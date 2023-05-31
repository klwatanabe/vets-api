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
        application_expiration_date

        { form526: @evss_claim }
      end

      private

      def claim_attributes
        @evss_claim[:claimantCertification] = @data[:claimantCertification]
        currentMailingAddress
        disabilities
        service_information

      def application_expiration_date
        @evss_claim[:applicationExpirationDate] = Date.today + 1.year
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
          disability[:approximateBeginDate] = map_date_to_obj disability[:approximateDate]
          disability[:secondaryDisabilities] = disability[:secondaryDisabilities].map do |secondary|
            secondary[:approximateBeginDate] = map_date_to_obj secondary[:approximateDate]
            secondary.except(:exposureOrEventOrInjury, :approximateDate)
          end

          if disability[:isRelatedToToxicExposure]
            disability[:specialIssues] = 'PACT'
          end

          disability.except(:approximateDate, :isRelatedToToxicExposure)
        end
      end

      def service_information
        info = @data[:serviceInformation]
        @evss_claim[:serviceInformation] = {
          servicePeriods: info[:servicePeriods],
          reservesNationalGuardService: {
            obligationTermOfServiceFromDate: info[:reservesNationalGuardService][:obligationTermsOfService][:startDate],
            obligationTermOfServiceToDate: info[:reservesNationalGuardService][:obligationTermsOfService][:endDate],
            unitName: info[:reservesNationalGuardService][:unitName],
          }
        }
      end

      def map_date_to_obj(date)
        date = if date.is_a? Date
          date
        else
          DateTime.parse(date)
        end
        { year: date.year, month: date.month, day: date.day }
      end
    end
  end
end
