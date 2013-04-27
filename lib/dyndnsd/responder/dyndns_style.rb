
module Dyndnsd
  module Responder
    class DynDNSStyle
      def response_for(state, ip = nil)
        # general http errors
        return [405, {"Content-Type" => "text/plain"}, ["Method Not Allowed"]] if state == :method_forbidden
        return [404, {"Content-Type" => "text/plain"}, ["Not Found"]] if state == :not_found
        # specific errors
        return [200, {"Content-Type" => "text/plain"}, ["notfqdn"]] if state == :hostname_missing
        return [200, {"Content-Type" => "text/plain"}, ["nohost"]] if state == :host_forbidden
        return [200, {"Content-Type" => "text/plain"}, ["notfqdn"]] if state == :hostname_malformed
        # OKs
        return [200, {"Content-Type" => "text/plain"}, ["good #{ip}"]] if state == :good
        return [200, {"Content-Type" => "text/plain"}, ["nochg #{ip}"]] if state == :nochg
      end
    end
  end
end
