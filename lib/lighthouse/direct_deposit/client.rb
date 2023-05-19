# frozen_string_literal: true

require 'common/client/base'
require 'lighthouse/direct_deposit/configuration'
require 'lighthouse/direct_deposit/payment_info_parser'
require 'lighthouse/direct_deposit/error_parser'
require 'lighthouse/service_exception'

module DirectDeposit
  class Client < Common::Client::Base
    configuration DirectDeposit::Configuration

    PATH = '/services/direct-deposit-management/v1/direct-deposit'
    STATSD_KEY_PREFIX = 'api.direct_deposit'

    def initialize(icn)
      @icn = icn
      raise ArgumentError, 'no ICN passed in for Lighthouse API request.' if icn.blank?

      super()
    end

    def get_payment_info
      response = config.get("?icn=#{@icn}")
      handle_response(response)
    rescue => e
      handle_error(e, 'CLIENT_ID', PATH)
    end

    def update_payment_info(params)
      body = build_request_body(params)

      response = config.put("?icn=#{@icn}", body)
      handle_response(response)
    rescue => e
      handle_error(e, 'CLIENT_ID', PATH)
    end

    private

    def handle_error(exception, _lighthouse_client_id, _url)
      # Request ID here?
      # Lighthouse::ServiceException.send_error_logs(
      #   exception,
      #   self.class.to_s.underscore,
      #   lighthouse_client_id, url
      # )

      Lighthouse::DirectDeposit::ErrorParser.parse(exception.response)
    end

    def handle_response(response)
      Lighthouse::DirectDeposit::PaymentInfoParser.parse(response)
    end

    def build_request_body(payment_account)
      {
        'paymentAccount' =>
        {
          'accountNumber' => payment_account.account_number,
          'accountType' => payment_account.account_type,
          'financialInstitutionRoutingNumber' => payment_account.routing_number
        }
      }.to_json
    end
  end
end
