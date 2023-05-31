# frozen_string_literal: true

module ClaimsApi
  module V2
    class DisabilityCompensationEvssMapper
      def initialize(auto_claim)
        @auto_claim = auto_claim
        @data = auto_claim&.form_data&.deep_symbolize_keys
        @evss_claim = {}
      end

      def map_claim
        claim_attributes

        @evss_claim
      end

      private

      def claim_attributes
        @evss_claim[:claimantCertification] = @data[:claimantCertification]
        currentMailingAddress
        disabilities
      end

      def currentMailingAddress
        addr = @data.dig(:veteranIdentification, :mailingAddress) || {}
        @evss_claim[:veteran] ||= {}
        @evss_claim[:veteran][:currentMailingAddress] = {
          addressLine1: addr[:numberAndStreet],
          addressLines2: addr[:apartmentOrUnitNumber],
          city: addr[:city],
          country: addr[:country],
          zipFirstFive: addr[:zipFirstFive],
          zipLastFour: addr[:zipLastFour],
          state: addr[:state],
        }
        @evss_claim[:veteran][:emailAddress] = @data.dig(:veteranIdentification, :emailAddress, :email)
        @evss_claim[:veteran][:fileNumber] = @data.dig(:veteranIdentification, :vaFileNumber) 
      end

      def disabilities
        @evss_claim[:disabilities] = @data[:disabilities].map do |disability|
          disability[:approximateBeginDate] = disability[:approximateDate]
          disability[:secondaryDisabilities] = disability[:secondaryDisabilities].map do |secondary|
            secondary[:approximateBeginDate] = secondary[:approximateDate]
            secondary.except(:exposureOrEventOrInjury, :approximateDate)
          end

          if disability[:isRelatedToToxicExposure]
            disability[:specialIssues] = 'PACT'
          end

          disability.except(:approximateDate, :isRelatedToToxicExposure)
        end
      end
    end
  end
end
