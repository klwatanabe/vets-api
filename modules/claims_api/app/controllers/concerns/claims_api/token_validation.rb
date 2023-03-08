# frozen_string_literal: true

require 'rest-client'

module ClaimsApi
  module TokenValidation
    extend ActiveSupport::Concern

    included do
      TOKEN_REGEX = /Bearer /.freeze
      def validate_token!

        return nil unless Settings.oidc.validation_url
        token_string = token_string_from_request
        payload = { aud: audience }
        response = RestClient.post(Settings.oidc.validation_url,
                                   payload,
                                   { Authorization: "Bearer #{token_string}",
                                     apiKey: Settings.oidc.validation_api_key })
        raise error_klass('Invalid token') if response.nil?

        JSON.parse(response.body) if response.code == 200
      rescue => e
        raise error_klass('Invalid token') if e.to_s.include?('Unauthorized')
      end
    end

    def token_string_from_request
      auth_request = request.authorization.to_s
      return unless auth_request[TOKEN_REGEX]
      token_string = auth_request.sub(TOKEN_REGEX, '').gsub(/^"|"$/, '')
    end
  end
end
