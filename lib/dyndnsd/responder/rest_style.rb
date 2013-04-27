
module Dyndnsd
  module Responder
    class RestStyle
      def response_for(state)
        # general http errors
        return [405, {"Content-Type" => "text/plain"}, ["Method Not Allowed"]] if state == :method_forbidden
        return [404, {"Content-Type" => "text/plain"}, ["Not Found"]] if state == :not_found
        # specific errors
        return [422, {"Content-Type" => "text/plain"}, ["Hostname missing"]] if state == :hostname_missing
        return [403, {"Content-Type" => "text/plain"}, ["Forbidden"]] if state == :host_forbidden
        return [422, {"Content-Type" => "text/plain"}, ["Hostname malformed"]] if state == :hostname_malformed
        # OKs
        return [200, {"Content-Type" => "text/plain"}, ["Good"]] if state == :good
        return [200, {"Content-Type" => "text/plain"}, ["No change"]] if state == :nochg
      end
    end
  end
end
