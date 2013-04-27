
module Dyndnsd
  module Generator
    class Bind
      def initialize(config)
        @ttl = config['ttl']
        @origin = config['origin']
        @dns = config['dns']
        @email_addr = config['email_addr']
      end

      def generate(zone)
        out = []
        out << "$TTL #{@ttl}"
        out << "$ORIGIN #{@origin}"
        out << ""
        out << "@ IN SOA #{@dns} #{@email_addr} ( #{zone['serial']} 3h 5m 1w 1h )"
        out << "@ IN NS #{@dns}"
        out << ""
        zone['hosts'].each do |hostname,ip|
          name = hostname.chomp('.' + @origin[0..-2])
          out << "#{name} IN A #{ip}"
        end
        out << ""
        out.join("\n")
      end
    end
  end
end
