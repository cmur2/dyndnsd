# typed: true

module Dyndnsd
  module Responder
    class RestStyle
      # @param app [#call]
      def initialize(app)
        @app = app
      end

      # @param env [Hash{String => String}]
      # @return [Array{Integer,Hash{String => String},Array{String}}]
      def call(env)
        @app.call(env).tap do |status_code, headers, body|
          if headers.key?('X-DynDNS-Response')
            return decorate_dyndnsd_response(status_code, headers, body)
          else
            return decorate_other_response(status_code, headers, body)
          end
        end
      end

      private

      # @param status_code [Integer]
      # @param headers [Hash{String => String}]
      # @param body [Array{String}]
      # @return [Array{Integer,Hash{String => String},Array{String}}]
      def decorate_dyndnsd_response(status_code, headers, body)
        if status_code == 200
          [200, {'Content-Type' => 'text/plain'}, [get_success_body(body[0], body[1])]]
        elsif status_code == 422
          error_response_map[headers['X-DynDNS-Response']]
        end
      end

      # @param status_code [Integer]
      # @param headers [Hash{String => String}]
      # @param _body [Array{String}]
      # @return [Array{Integer,Hash{String => String},Array{String}}]
      def decorate_other_response(status_code, headers, _body)
        if status_code == 400
          [status_code, headers, ['Bad Request']]
        elsif status_code == 401
          [status_code, headers, ['Unauthorized']]
        end
      end

      # @param changes [Array{Symbol}]
      # @param myips [Array{String}]
      # @return [String]
      def get_success_body(changes, myips)
        changes.map { |change| change == :good ? "Changed to #{myips.join(' ')}" : "No change needed for #{myips.join(' ')}" }.join("\n")
      end

      # @return [Hash{String => Object}]
      def error_response_map
        {
          # general http errors
          'method_forbidden'   => [405, {'Content-Type' => 'text/plain'}, ['Method Not Allowed']],
          'not_found'          => [404, {'Content-Type' => 'text/plain'}, ['Not Found']],
          # specific errors
          'hostname_missing'   => [422, {'Content-Type' => 'text/plain'}, ['Hostname missing']],
          'hostname_malformed' => [422, {'Content-Type' => 'text/plain'}, ['Hostname malformed']],
          'host_forbidden'     => [403, {'Content-Type' => 'text/plain'}, ['Forbidden']]
        }
      end
    end
  end
end
