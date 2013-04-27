#!/usr/bin/env ruby

require 'logger'
require 'ipaddr'
require 'json'
require 'yaml'
require 'rack'

require 'dyndnsd/generator/bind'
require 'dyndnsd/updater/command_with_bind_zone'
require 'dyndnsd/responder/rest_style'
require 'dyndnsd/database'
require 'dyndnsd/version'

module Dyndnsd
  def self.logger
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  class LogFormatter
    def call(lvl, time, progname, msg)
      "%s: %s\n" % [lvl, msg.to_s]
    end
  end

  class Daemon
    def initialize(config, db, updater, responder)
      @users = config['users']
      @db = db
      @updater = updater
      @responder = responder

      @db.load
      @db['serial'] ||= 1
      @db['hosts'] ||= {}
      (@db.save; update) if @db.changed?
    end
    
    def update
      @updater.update(@db)
    end
    
    def call(env)
      return @responder.response_for(:method_forbidden) if env["REQUEST_METHOD"] != "GET"
      return @responder.response_for(:not_found) if env["PATH_INFO"] != "/nic/update"
      
      params = Rack::Utils.parse_query(env["QUERY_STRING"])
      
      return @responder.response_for(:hostname_missing) if not params["hostname"]
      
      hostname = params["hostname"]
      
      # Check if hostname(s) match rules
      #return @responder.response_for(:hostname_malformed) if XY
      
      user = env["REMOTE_USER"]
      
      return @responder.response_for(:host_forbidden) if not @users[user]['hosts'].include? hostname
      
      # no myip?
      if not params["myip"]
        params["myip"] = env["REMOTE_ADDR"]
      end
      
      # malformed myip?
      begin
        IPAddr.new(params["myip"], Socket::AF_INET)
      rescue ArgumentError
        params["myip"] = env["REMOTE_ADDR"]
      end
      
      myip = params["myip"]
      
      @db['hosts'][hostname] = myip    
      
      if @db.changed?
        @db['serial'] += 1
        @db.save
        update
        return @responder.response_for(:good, myip)
      end
      
      @responder.response_for(:nochg, myip)
    end

    def self.run!
      Dyndnsd.logger = Logger.new(STDOUT)
      Dyndnsd.logger.formatter = LogFormatter.new

      if ARGV.length != 1
        puts "Usage: dyndnsd config_file"
        exit 1
      end

      config_file = ARGV[0]

      if not File.file?(config_file)
        Dyndnsd.logger.fatal "Config file not found!"
        exit 1
      end

      Dyndnsd.logger.info "DynDNSd version #{Dyndnsd::VERSION}"
      Dyndnsd.logger.info "Using config file #{config_file}"

      config = YAML::load(File.open(config_file, 'r') { |f| f.read })

      db = Database.new(config['db'])
      updater = Updater::CommandWithBindZone.new(config['updater']['params']) if config['updater']['name'] == 'command_with_bind_zone'
      responder = Responder::RestStyle.new
      
      app = Daemon.new(config, db, updater, responder)
      app = Rack::Auth::Basic.new(app, "DynDNS") do |user,pass|
        (config['users'].has_key? user) and (config['users'][user]['password'] == pass)
      end

      Signal.trap('INT') do
        Rack::Handler::WEBrick.shutdown
      end

      Rack::Handler::WEBrick.run app, :Host => config['host'], :Port => config['port']
    end
  end
end
