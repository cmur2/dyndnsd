
require 'ipaddr'

module Dyndnsd
  class Helper
    def self.fqdn_valid?(hostname, domain)
      return false if hostname.length < domain.length + 2
      return false if !hostname.end_with?(domain)
      name = hostname.chomp(domain)
      return false if !name.match(/^[a-zA-Z0-9_-]+\.$/)
      true
    end

    def self.ip_valid?(ip)
      IPAddr.new(ip)
      return true
    rescue ArgumentError
      return false
    end
  end
end
