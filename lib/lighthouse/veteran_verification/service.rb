# frozen_string_literal: true

require 'common/client/base'
require 'lighthouse/veteran_verification/configuration'
require 'lighthouse/veteran_verification/service_exception'

module VeteranVerification
  class Service < Common::Client::Base
    configuration VeteranVerification::Configuration
    STATSD_KEY_PREFIX = 'api.veteran_verification'

    # @param [string] lighthouse_client_id: the lighthouse_client_id requested from Lighthouse
    # @param [string] lighthouse_rsa_key_path: path to the private RSA key used to create the lighthouse_client_id
    # @param [hash] options: options to override aud_claim_url, params, and auth_params
    # @option options [hash] :params body for the request
    # @option options [string] :aud_claim_url option to override the aud_claim_url for LH Veteran Verification APIs
    # @option options [hash] :auth_params a hash to send in auth params to create the access token
    # @option options [string] :host a base host for the Lighthouse API call
    def get_rated_disabilities(lighthouse_client_id, lighthouse_rsa_key_path, options = {})
      config
        .get(
          'disability_rating',
          lighthouse_client_id,
          lighthouse_rsa_key_path,
          options
        )
        .body
    rescue Faraday::ClientError => e
      Rails.logger.error(
        VeteranVerification::ServiceException.new(e.response),
        "#{lighthouse_client_id} get_rated_disabilities Lighthouse Error"
      )
    end
  end
end
