
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
      true
    rescue ArgumentError
      false
    end

    def self.user_allowed?(username, password, users)
      (users.key? username) && (users[username]['password'] == password)
    end

    def self.changed?(hostname, myips, hosts)
      # myips order is always deterministic
      ((!hosts.include? hostname) || (hosts[hostname] != myips)) && !myips.empty?
    end

    def self.span(operation, &block)
      span = OpenTracing.start_span(operation)
      span.set_tag('component', 'dyndnsd')
      span.set_tag('span.kind', 'server')
      begin
        block.call(span)
      ensure
        span.finish
      end
    end
  end
end
