# frozen_string_literal: true

require 'resolv'
require 'securerandom'

require 'async/dns'

module Dyndnsd
  module Updater
    class ZoneTransferServer
      DEFAULT_SERVER_LISTENS = ['0.0.0.0@53'].freeze

      # @param domain [String]
      # @param updater_params [Hash{String => Object}]
      def initialize(domain, updater_params)
        @domain = domain

        @server_listens = self.class.parse_endpoints(updater_params['server_listens'] || DEFAULT_SERVER_LISTENS)
        @notify_targets = (updater_params['send_notifies'] || []).map { |e| self.class.parse_endpoints([e]) }

        @zone_rr_ttl = updater_params['zone_ttl']
        @zone_nameservers = updater_params['zone_nameservers'].map { |n| Resolv::DNS::Name.create(n) }
        @zone_email_address = Resolv::DNS::Name.create(updater_params['zone_email_address'])
        @zone_additional_ips = updater_params['zone_additional_ips'] || []

        @server = ZoneTransferServerHelper.new(@server_listens, @domain)

        # run Async::DNS server in background thread
        Thread.new do
          @server.run
        end
      end

      # @param db [Dyndnsd::Database]
      # @return [void]
      def update(db)
        Helper.span('updater_update') do |span|
          span.set_tag('dyndnsd.updater.name', self.class.name&.split('::')&.last || 'None')

          soa_rr = Resolv::DNS::Resource::IN::SOA.new(
            @zone_nameservers[0], @zone_email_address,
            db['serial'],
            10_800,  # 3h
            300,     # 5m
            604_800, # 1w
            3_600    # 1h
          )

          default_options = {ttl: @zone_rr_ttl}

          # array containing all resource records for an AXFR request in the right order
          rrs = []
          # AXFR responses need to start with zone's SOA RR
          rrs << [soa_rr, default_options]

          # return RRs for all of the zone's nameservers
          @zone_nameservers.each do |ns|
            rrs << [Resolv::DNS::Resource::IN::NS.new(ns), default_options]
          end

          # return A/AAAA RRs for all additional IPv4s/IPv6s for the domain itself
          @zone_additional_ips.each do |ip|
            rrs << [create_addr_rr_for_ip(ip), default_options]
          end

          # return A/AAAA RRs for the dyndns hostnames
          db['hosts'].each do |hostname, ips|
            ips.each do |ip|
              rrs << [create_addr_rr_for_ip(ip), default_options.merge({name: hostname})]
            end
          end

          # AXFR responses need to end with zone's SOA RR again
          rrs << [soa_rr, default_options]

          # point Async::DNS server thread's variable to this new RR array
          @server.axfr_rrs = rrs

          # only send DNS NOTIFY if there really was a change
          if db.changed?
            send_dns_notify
          end
        end
      end

      # converts into suitable parameter form for Async::DNS::Resolver or Async::DNS::Server
      #
      # @param endpoint_list [Array<String>]
      # @return [Array{Array{Object}}]
      def self.parse_endpoints(endpoint_list)
        endpoint_list.map { |addr_string| addr_string.split('@') }
                     .map { |addr_parts| [addr_parts[0], addr_parts[1].to_i || 53] }
                     .map { |addr| [:tcp, :udp].map { |type| [type] + addr } }
                     .flatten(1)
      end

      private

      # creates correct Resolv::DNS::Resource object for IP address type
      #
      # @param ip_string [String]
      # @return [Resolv::DNS::Resource::IN::A,Resolv::DNS::Resource::IN::AAAA]
      def create_addr_rr_for_ip(ip_string)
        ip = IPAddr.new(ip_string).native

        if ip.ipv6?
          Resolv::DNS::Resource::IN::AAAA.new(ip.to_s)
        else
          Resolv::DNS::Resource::IN::A.new(ip.to_s)
        end
      end

      # https://tools.ietf.org/html/rfc1996
      #
      # @return [void]
      def send_dns_notify
        Async::Reactor.run do
          @notify_targets.each do |notify_target|
            target = Async::DNS::Resolver.new(notify_target)

            # assemble DNS NOTIFY message
            request = Resolv::DNS::Message.new(SecureRandom.random_number(2**16))
            request.opcode = Resolv::DNS::OpCode::Notify
            request.add_question("#{@domain}.", Resolv::DNS::Resource::IN::SOA)

            _response = target.dispatch_request(request)
          end
        end
      end
    end

    class ZoneTransferServerHelper < Async::DNS::Server
      attr_accessor :axfr_rrs

      def initialize(endpoints, domain)
        super(endpoints, logger: Dyndnsd.logger)
        @domain = domain
      end

      # @param name [String]
      # @param resource_class [Resolv::DNS::Resource]
      # Since solargraph cannot parse this: param transaction [Async::DNS::Transaction]
      # @return [void]
      def process(name, resource_class, transaction)
        if name != @domain || resource_class != Resolv::DNS::Resource::Generic::Type252_Class1
          transaction.fail!(:NXDomain)
          return
        end

        # https://tools.ietf.org/html/rfc5936
        transaction.append_question!
        @axfr_rrs.each do |rr|
          transaction.add([rr[0]], rr[1])
        end
      end
    end
  end
end
