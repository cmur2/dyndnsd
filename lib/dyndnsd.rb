# frozen_string_literal: true

require 'date'
require 'etc'
require 'logger'
require 'ipaddr'
require 'json'
require 'yaml'
require 'rack'
require 'rackup'
require 'metriks'
require 'opentelemetry/instrumentation/rack'
require 'opentelemetry/sdk'
require 'metriks/reporter/graphite'

require 'dyndnsd/generator/bind'
require 'dyndnsd/updater/command_with_bind_zone'
require 'dyndnsd/updater/zone_transfer_server'
require 'dyndnsd/responder/dyndns_style'
require 'dyndnsd/responder/rest_style'
require 'dyndnsd/database'
require 'dyndnsd/helper'
require 'dyndnsd/textfile_reporter'
require 'dyndnsd/version'

module Dyndnsd
  # @return [Logger]
  def self.logger
    @logger
  end

  # @param logger [Logger]
  # @return [Logger]
  def self.logger=(logger)
    @logger = logger
  end

  class LogFormatter
    # @param lvl [Object]
    # @param _time [DateTime]
    # @param _progname [String]
    # @param msg [Object]
    # @return [String]
    def call(lvl, _time, _progname, msg)
      format("[%s] %-5s %s\n", Time.now.strftime('%Y-%m-%d %H:%M:%S'), lvl, msg.to_s)
    end
  end

  class Daemon
    # @param config [Hash{String => Object}]
    # @param db [Dyndnsd::Database]
    # @param updater [#update]
    def initialize(config, db, updater)
      @users = config['users']
      @domain = config['domain']
      @db = db
      @updater = updater

      @db.load
      @db['serial'] ||= 1
      @db['hosts'] ||= {}
      @updater.update(@db)
      if @db.changed?
        @db.save
      end
    end

    # @param username [String]
    # @param password [String]
    # @return [Boolean]
    def authorized?(username, password)
      Helper.span('check_authorized') do |span|
        span.set_attribute('enduser.id', username)

        allow = Helper.user_allowed?(username, password, @users)
        if !allow
          Dyndnsd.logger.warn "Login failed for #{username}"
          Metriks.meter('requests.auth_failed').mark
        end
        allow
      end
    end

    # @param env [Hash{String => String}]
    # @return [Array{Integer,Hash{String => String},Array<String>}]
    def call(env)
      return [422, {'X-DynDNS-Response' => 'method_forbidden'}, []] if env['REQUEST_METHOD'] != 'GET'
      return [422, {'X-DynDNS-Response' => 'not_found'}, []] if env['PATH_INFO'] != '/nic/update'

      handle_dyndns_request(env)
    end

    # @return [void]
    def self.run!
      if ARGV.length != 1
        puts 'Usage: dyndnsd config_file'
        exit 1
      end

      config_file = ARGV[0]

      if !File.file?(config_file)
        puts 'Config file not found!'
        exit 1
      end

      puts "DynDNSd version #{Dyndnsd::VERSION}"
      puts "Using config file #{config_file}"

      config = YAML.safe_load_file(config_file)

      setup_logger(config)

      Dyndnsd.logger.info 'Starting...'

      # drop privileges as soon as possible
      # NOTE: first change group than user
      if config['group']
        group = Etc.getgrnam(config['group'])
        Process::Sys.setgid(group.gid) if group
      end
      if config['user']
        user = Etc.getpwnam(config['user'])
        Process::Sys.setuid(user.uid) if user
      end

      setup_traps

      setup_monitoring(config)

      setup_tracing(config)

      setup_rack(config)
    end

    private

    # @param params [Hash{String => String}]
    # @return [Array<String>]
    def extract_v4_and_v6_address(params)
      return [] if !params['myip']
      begin
        IPAddr.new(params['myip'], Socket::AF_INET)
        IPAddr.new(params['myip6'], Socket::AF_INET6)
        [params['myip'], params['myip6']]
      rescue ArgumentError
        []
      end
    end

    # @param env [Hash{String => String}]
    # @param params [Hash{String => String}]
    # @return [Array<String>]
    def extract_myips(env, params)
      # require presence of myip parameter as valid IPAddr (v4) and valid myip6
      return extract_v4_and_v6_address(params) if params.key?('myip6')

      # check whether myip parameter has valid IPAddr
      return [params['myip']] if params.key?('myip') && Helper.ip_valid?(params['myip'])

      # check whether X-Real-IP header has valid IPAddr
      return [env['HTTP_X_REAL_IP']] if env.key?('HTTP_X_REAL_IP') && Helper.ip_valid?(env['HTTP_X_REAL_IP'])

      # fallback value, always present
      [env['REMOTE_ADDR']]
    end

    # @param hostnames [String]
    # @param myips [Array<String>]
    # @return [Array<Symbol>]
    def process_changes(hostnames, myips)
      changes = []
      Helper.span('process_changes') do |span|
        span.set_attribute('dyndnsd.hostnames', hostnames.join(','))

        hostnames.each do |hostname|
          # myips order is always deterministic
          if myips.empty? && @db['hosts'].include?(hostname)
            @db['hosts'].delete(hostname)
            changes << :good
            Metriks.meter('requests.good').mark
          elsif Helper.changed?(hostname, myips, @db['hosts'])
            @db['hosts'][hostname] = myips
            changes << :good
            Metriks.meter('requests.good').mark
          else
            changes << :nochg
            Metriks.meter('requests.nochg').mark
          end
        end
      end
      changes
    end

    # @return [void]
    def update_db
      @db['serial'] += 1
      Dyndnsd.logger.info "Committing update ##{@db['serial']}"
      @updater.update(@db)
      @db.save
      Metriks.meter('updates.committed').mark
    end

    # @param env [Hash{String => String}]
    # @return [Array{Integer,Hash{String => String},Array<String>}]
    def handle_dyndns_request(env)
      params = Rack::Utils.parse_query(env['QUERY_STRING'])

      # require hostname parameter
      return [422, {'X-DynDNS-Response' => 'hostname_missing'}, []] if !params['hostname']

      hostnames = params['hostname'].split(',')

      # check for invalid hostnames
      invalid_hostnames = hostnames.select { |h| !Helper.fqdn_valid?(h, @domain) }
      return [422, {'X-DynDNS-Response' => 'hostname_malformed'}, []] if invalid_hostnames.any?

      # we can trust this information since user was authorized by middleware
      user = env['REMOTE_USER']

      # check for hostnames that the user does not own
      forbidden_hostnames = hostnames - @users[user].fetch('hosts', [])
      return [422, {'X-DynDNS-Response' => 'host_forbidden'}, []] if forbidden_hostnames.any?

      if params['offline'] == 'YES'
        myips = []
      else
        myips = extract_myips(env, params)
        # require at least one IP to update
        return [422, {'X-DynDNS-Response' => 'host_forbidden'}, []] if myips.empty?
      end

      Metriks.meter('requests.valid').mark
      Dyndnsd.logger.info "Request to update #{hostnames} to #{myips} for user #{user}"

      changes = process_changes(hostnames, myips)

      update_db if @db.changed?

      [200, {'X-DynDNS-Response' => 'success'}, [changes, myips]]
    end

    # SETUP

    # @param config [Hash{String => Object}]
    # @return [void]
    private_class_method def self.setup_logger(config)
      if config['logfile']
        Dyndnsd.logger = Logger.new(config['logfile'])
      else
        Dyndnsd.logger = Logger.new($stdout)
      end

      Dyndnsd.logger.progname = 'dyndnsd'
      Dyndnsd.logger.formatter = LogFormatter.new
      Dyndnsd.logger.level = config['debug'] ? Logger::DEBUG : Logger::INFO

      OpenTelemetry.logger = Dyndnsd.logger
    end

    # @return [void]
    private_class_method def self.setup_traps
      Signal.trap('INT') do
        Rackup::Handler::WEBrick.shutdown
      end
      Signal.trap('TERM') do
        Rackup::Handler::WEBrick.shutdown
      end
    end

    # @param config [Hash{String => Object}]
    # @return [void]
    private_class_method def self.setup_monitoring(config)
      # configure metriks
      if config['graphite']
        host = config['graphite']['host'] || 'localhost'
        port = config['graphite']['port'] || 2003
        options = {}
        options[:prefix] = config['graphite']['prefix'] if config['graphite']['prefix']
        reporter = Metriks::Reporter::Graphite.new(host, port, options)
        reporter.start
      elsif config['textfile']
        file = config['textfile']['file'] || '/tmp/dyndnsd-metrics.prom'
        options = {}
        options[:prefix] = config['textfile']['prefix'] if config['textfile']['prefix']
        reporter = Dyndnsd::TextfileReporter.new(file, options)
        reporter.start
      else
        reporter = Metriks::Reporter::ProcTitle.new
        reporter.add 'good', 'sec' do
          Metriks.meter('requests.good').mean_rate
        end
        reporter.add 'nochg', 'sec' do
          Metriks.meter('requests.nochg').mean_rate
        end
        reporter.start
      end
    end

    # @param config [Hash{String => Object}]
    # @return [void]
    private_class_method def self.setup_tracing(config)
      # by default do not try to emit any traces until the user opts in
      ENV['OTEL_TRACES_EXPORTER'] ||= 'none'

      # configure OpenTelemetry
      OpenTelemetry::SDK.configure do |c|
        if config.dig('tracing', 'jaeger')
          require 'opentelemetry/exporter/jaeger'

          c.add_span_processor(
            OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
              OpenTelemetry::Exporter::Jaeger::AgentExporter.new
            )
          )
        end

        if config.dig('tracing', 'service_name')
          c.service_name = config['tracing']['service_name']
        end

        c.service_version = Dyndnsd::VERSION
        c.use('OpenTelemetry::Instrumentation::Rack')
      end

      if !config.dig('tracing', 'trust_incoming_span')
        OpenTelemetry.propagation = OpenTelemetry::Context::Propagation::NoopTextMapPropagator.new
      end
    end

    # @param config [Hash{String => Object}]
    # @return [void]
    private_class_method def self.setup_rack(config)
      # configure daemon
      db = Database.new(config['db'])
      case config.dig('updater', 'name')
      when 'command_with_bind_zone'
        updater = Updater::CommandWithBindZone.new(config['domain'], config.dig('updater', 'params'))
      when 'zone_transfer_server'
        updater = Updater::ZoneTransferServer.new(config['domain'], config.dig('updater', 'params'))
      end
      daemon = Daemon.new(config, db, updater)

      # configure rack
      app = Rack::Auth::Basic.new(daemon, 'DynDNS', &daemon.method(:authorized?))

      if config['responder'] == 'RestStyle'
        app = Responder::RestStyle.new(app)
      else
        app = Responder::DynDNSStyle.new(app)
      end

      app = OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware.new(app)

      Rackup::Handler::WEBrick.run app, Host: config['host'], Port: config['port']
    end
  end
end
