
module Dyndnsd
  module Responder
    class RestStyle
      def response_for_error(state)
        # general http errors
        return [405, {"Content-Type" => "text/plain"}, ["Method Not Allowed"]] if state == :method_forbidden
        return [404, {"Content-Type" => "text/plain"}, ["Not Found"]] if state == :not_found
        # specific errors
        return [422, {"Content-Type" => "text/plain"}, ["Hostname missing"]] if state == :hostname_missing
        return [403, {"Content-Type" => "text/plain"}, ["Forbidden"]] if state == :host_forbidden
        return [422, {"Content-Type" => "text/plain"}, ["Hostname malformed"]] if state == :hostname_malformed
      end
      
      def response_for_changes(states, ip)
        body = states.map { |state| state == :good ? "Changed to #{ip}" : "No change needed for #{ip}" }.join("\n")
        return [200, {"Content-Type" => "text/plain"}, [body]]
      end
    end
  end
end
