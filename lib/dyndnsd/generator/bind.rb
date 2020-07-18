# frozen_string_literal: true

module Dyndnsd
  module Generator
    class Bind
      # @param domain [String]
      # @param updater_params [Hash{String => Object}]
      def initialize(domain, updater_params)
        @domain = domain
        @ttl = updater_params['ttl']
        @dns = updater_params['dns']
        @email_addr = updater_params['email_addr']
        @additional_zone_content = updater_params['additional_zone_content']
      end

      # @param db [Dyndnsd::Database]
      # @return [String]
      def generate(db)
        out = []
        out << "$TTL #{@ttl}"
        out << "$ORIGIN #{@domain}."
        out << ''
        out << "@ IN SOA #{@dns} #{@email_addr} ( #{db['serial']} 3h 5m 1w 1h )"
        out << "@ IN NS #{@dns}"
        out << ''
        db['hosts'].each do |hostname, ips|
          ips.each do |ip|
            ip = IPAddr.new(ip).native
            type = ip.ipv6? ? 'AAAA' : 'A'
            name = hostname.chomp('.' + @domain)
            out << "#{name} IN #{type} #{ip}"
          end
        end
        out << ''
        out << @additional_zone_content
        out << ''
        out.join("\n")
      end
    end
  end
end
