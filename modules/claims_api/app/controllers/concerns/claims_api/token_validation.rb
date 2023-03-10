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
        root_url = request.base_url == 'https://api.va.gov' ? 'https://api.va.gov' : 'https://sandbox-api.va.gov'
        audience = "#{root_url}/services/claims"
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

    def user_from_validated_token(validated_token)
      attributes = validated_token['attributes']
      ttl = attributes['exp'] - Time.current.utc.to_i
      uid = attributes['uid']
      act = attributes['act']
      icn = act['icn']
      claims_user = ClaimsUser.new(attributes['uid'])
      claims_user.set_icn(icn) unless icn.nil?
      unless attributes['last_name'].nil?
        claims_user.first_name_last_name(attributes['first_name'], attributes['last_name'])
      end
      claims_user
    end
  end
end
