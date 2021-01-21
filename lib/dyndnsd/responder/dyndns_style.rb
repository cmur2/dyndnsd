# frozen_string_literal: true

module Dyndnsd
  module Responder
    class DynDNSStyle
      # @param app [#call]
      def initialize(app)
        @app = app
      end

      # @param env [Hash{String => String}]
      # @return [Array{Integer,Hash{String => String},Array<String>}]
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
      # @param body [Array<String>]
      # @return [Array{Integer,Hash{String => String},Array<String>}]
      def decorate_dyndnsd_response(status_code, headers, body)
        case status_code
        when 200
          [200, {'Content-Type' => 'text/plain'}, [get_success_body(body[0], body[1])]]
        when 422
          error_response_map[headers['X-DynDNS-Response']]
        end
        # TODO: possible nil response!
      end

      # @param status_code [Integer]
      # @param headers [Hash{String => String}]
      # @param _body [Array<String>]
      # @return [Array{Integer,Hash{String => String},Array<String>}]
      def decorate_other_response(status_code, headers, _body)
        case status_code
        when 400
          [status_code, headers, ['Bad Request']]
        when 401
          [status_code, headers, ['badauth']]
        end
        # TODO: possible nil response!
      end

      # @param changes [Array<Symbol>]
      # @param myips [Array<String>]
      # @return [String]
      def get_success_body(changes, myips)
        changes.map { |change| "#{change} #{myips.join(' ')}" }.join("\n")
      end

      # @return [Hash{String => Object}]
      def error_response_map
        {
          # general http errors
          'method_forbidden'   => [405, {'Content-Type' => 'text/plain'}, ['Method Not Allowed']],
          'not_found'          => [404, {'Content-Type' => 'text/plain'}, ['Not Found']],
          # specific errors
          'hostname_missing'   => [200, {'Content-Type' => 'text/plain'}, ['notfqdn']],
          'hostname_malformed' => [200, {'Content-Type' => 'text/plain'}, ['notfqdn']],
          'host_forbidden'     => [200, {'Content-Type' => 'text/plain'}, ['nohost']]
        }
      end
    end
  end
end
