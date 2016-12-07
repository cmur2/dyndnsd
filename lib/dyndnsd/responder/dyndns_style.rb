
module Dyndnsd
  module Responder
    class DynDNSStyle
      def response_for_error(state)
        # general http errors
        return [405, {"Content-Type" => "text/plain"}, ["Method Not Allowed"]] if state == :method_forbidden
        return [404, {"Content-Type" => "text/plain"}, ["Not Found"]] if state == :not_found
        # specific errors
        return [200, {"Content-Type" => "text/plain"}, ["notfqdn"]] if state == :hostname_missing
        return [200, {"Content-Type" => "text/plain"}, ["nohost"]] if state == :host_forbidden
        return [200, {"Content-Type" => "text/plain"}, ["notfqdn"]] if state == :hostname_malformed
      end

      def response_for_changes(states, ip)
        body = states.map { |state| "#{state} #{ip.is_a?(Array) ? ip.join(' ') : ip}" }.join("\n")
        return [200, {"Content-Type" => "text/plain"}, [body]]
      end
    end
  end
end
