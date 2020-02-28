# typed: true

module Dyndnsd
  module Generator
    class Bind
      def initialize(domain, config)
        @domain = domain
        @ttl = config['ttl']
        @dns = config['dns']
        @email_addr = config['email_addr']
        @additional_zone_content = config['additional_zone_content']
      end

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
