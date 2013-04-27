#!/usr/bin/env ruby

require 'logger'
require 'ipaddr'
require 'json'
require 'yaml'
require 'rack'

require 'dyndnsd/generator/bind'
require 'dyndnsd/updater/command_with_bind_zone'
require 'dyndnsd/responder/dyndns_style'
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
      @domain = config['domain']
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
    
    def is_fqdn_valid?(hostname)
      return false if hostname.length < @domain.length + 2
      return false if not hostname.end_with?(@domain)
      name = hostname.chomp(@domain)
      return false if not name.match(/^[a-zA-Z0-9_-]+\.$/)
      true
    end
    
    def call(env)
      return @responder.response_for_error(:method_forbidden) if env["REQUEST_METHOD"] != "GET"
      return @responder.response_for_error(:not_found) if env["PATH_INFO"] != "/nic/update"
      
      params = Rack::Utils.parse_query(env["QUERY_STRING"])
      
      return @responder.response_for_error(:hostname_missing) if not params["hostname"]
      
      hostnames = params["hostname"].split(',')
      
      # Check if hostname match rules
      hostnames.each do |hostname|
        return @responder.response_for_error(:hostname_malformed) if not is_fqdn_valid?(hostname)
      end
      
      user = env["REMOTE_USER"]
      
      hostnames.each do |hostname|
        return @responder.response_for_error(:host_forbidden) if not @users[user]['hosts'].include? hostname
      end
      
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
      
      changes = []
      hostnames.each do |hostname|
        if (not @db['hosts'].include? hostname) or (@db['hosts'][hostname] != myip)
          changes << :good
          @db['hosts'][hostname] = myip
        else
          changes << :nochg
        end
      end
      
      if @db.changed?
        @db['serial'] += 1
        @db.save
        update
      end
      
      @responder.response_for_changes(changes, myip)
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
      updater = Updater::CommandWithBindZone.new(config['domain'], config['updater']['params']) if config['updater']['name'] == 'command_with_bind_zone'
      responder = Responder::DynDNSStyle.new
      
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
