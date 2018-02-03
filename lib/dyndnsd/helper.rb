
require 'ipaddr'

module Dyndnsd
  class Helper
    def self.is_fqdn_valid?(hostname, domain)
      return false if hostname.length < domain.length + 2
      return false if not hostname.end_with?(domain)
      name = hostname.chomp(domain)
      return false if not name.match(/^[a-zA-Z0-9_-]+\.$/)
      true
    end

    def self.is_ip_valid?(ip)
      begin
        IPAddr.new(ip)
        return true
      rescue ArgumentError
        return false
      end
    end
  end
end
