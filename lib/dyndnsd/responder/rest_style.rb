
module Dyndnsd
  module Responder
    class RestStyle
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env).tap do |status_code, headers, body|
          if headers.has_key?("X-DynDNS-Response")
            return decorate_dyndnsd_response(status_code, headers, body)
          else
            return decorate_other_response(status_code, headers, body)
          end
        end
      end

      private

      def decorate_dyndnsd_response(status_code, headers, body)
        if status_code == 200
          [200, {"Content-Type" => "text/plain"}, [get_success_body(body[0], body[1])]]
        elsif status_code == 422
          get_error_response_map[headers["X-DynDNS-Response"]]
        end
      end

      def decorate_other_response(status_code, headers, body)
        if status_code == 400
          [status_code, headers, "Bad Request"]
        elsif status_code == 401
          [status_code, headers, "Unauthorized"]
        end
      end


      def get_success_response(states, ip)
        ips = ip.is_a?(Array) ? ip.join(' ') : ip
        states.map { |state| state == :good ? "Changed to #{ips}" : "No change needed for #{ips}" }.join("\n")
      end

      def get_error_response_map
        {
          # general http errors
          'method_forbidden'   => [405, {"Content-Type" => "text/plain"}, ["Method Not Allowed"]],
          'not_found'          => [404, {"Content-Type" => "text/plain"}, ["Not Found"]],
          # specific errors
          'hostname_missing'   => [422, {"Content-Type" => "text/plain"}, ["Hostname missing"]],
          'hostname_malformed' => [422, {"Content-Type" => "text/plain"}, ["Hostname malformed"]],
          'host_forbidden'     => [403, {"Content-Type" => "text/plain"}, ["Forbidden"]]
        }
      end
    end
  end
end
