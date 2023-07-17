# frozen_string_literal: true

require 'lighthouse/letters_generator/configuration'
require 'lighthouse/service_exception'

module Lighthouse
  module LettersGenerator
    def self.measure_time(msg)
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      response = yield

      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed = end_time - start_time

      Rails.logger.info "#{msg}: #{elapsed} seconds"
      response
    end

    class Service < Common::Client::Base
      LETTER_TYPES = %w[
        benefit_summary
        benefit_summary_dependent
        benefit_verification
        certificate_of_eligibility
        civil_service
        commissary
        medicare_partd
        minimum_essential_coverage
        proof_of_service
        service_verification
      ].to_set.freeze

      BENEFICIARY_KEY_TRANFORMS = {
        awardEffectiveDateTime: :awardEffectiveDate,
        chapter35Eligibility: :hasChapter35Eligibility,
        nonServiceConnectedPension: :hasNonServiceConnectedPension,
        serviceConnectedDisabilities: :hasServiceConnectedDisabilities,
        adaptedHousing: :hasAdaptedHousing,
        individualUnemployabilityGranted: :hasIndividualUnemployabilityGranted,
        specialMonthlyCompensation: :hasSpecialMonthlyCompensation
      }.freeze

      configuration Lighthouse::LettersGenerator::Configuration

      def get_letter(icn, letter_type, options = {})
        validate_downloadable_letter_type(letter_type)

        endpoint = "letter-contents/#{letter_type}"
        log = "Retrieving letter from #{config.generator_url}/#{endpoint}"
        params = { icn: }.merge(options)

        get_from_lighthouse(endpoint, params, log)
      end

      def get_eligible_letter_types(icn)
        endpoint = 'eligible-letters'
        log = "Retrieving eligible letter types and destination from #{config.generator_url}/#{endpoint}"
        params = { icn: }

        response_body = get_from_lighthouse(endpoint, params, log)

        {
          letters: transform_letters(response_body['letters']),
          letter_destination: response_body['letterDestination']
        }
      end

      def get_benefit_information(icn)
        endpoint = 'eligible-letters'
        log = "Retrieving benefit information from #{config.generator_url}/#{endpoint}"
        params = { icn: }

        response_body = get_from_lighthouse(endpoint, params, log)

        {
          benefitInformation: transform_benefit_information(response_body['benefitInformation']),
          militaryService: transform_military_services(response_body['militaryServices'])
        }
      end

      def download_letter(icn, letter_type, options = {})
        validate_downloadable_letter_type(letter_type)

        endpoint = "letters/#{letter_type}/letter"
        log = "Downloading letter from #{config.generator_url}/#{endpoint}"
        params = { icn: }.merge(options)

        get_from_lighthouse(endpoint, params, log)
      end

      private

      def get_from_lighthouse(endpoint, params, log)
        Lighthouse::LettersGenerator.measure_time(log) do
          response = config.connection.get(
            endpoint,
            params,
            { Authorization: "Bearer #{config.get_access_token}" }
          )
          response.body
        end
      rescue Faraday::ClientError, Faraday::ServerError => e
        Raven.tags_context(
          team: 'benefits-claim-appeal-status',
          feature: 'letters-generator'
        )
        Lighthouse::ServiceException.send_error(
          e,
          self.class.to_s.underscore,
          config.service_name,
          "#{config.generator_url}/#{endpoint}"
        )
      end

      def transform_letters(letters)
        letters.map do |letter|
          {
            letterType: letter['letterType'].downcase,
            name: letter['letterName']
          }
        end
      end

      def transform_military_services(services_info)
        services_info.map do |service|
          service[:enteredDate] = service.delete 'enteredDateTime'
          service[:releasedDate] = service.delete 'releasedDateTime'

          service.transform_keys(&:to_sym)
        end
      end

      def transform_benefit_information(info)
        symbolized_info = info.deep_transform_keys(&:to_sym)

        transformed_info = symbolized_info.reduce({}) do |acc, (k, v)|
          if BENEFICIARY_KEY_TRANFORMS.key? k
            acc.merge({ BENEFICIARY_KEY_TRANFORMS[k] => v })
          else
            acc.merge({ k => v })
          end
        end

        monthly_award_amount = symbolized_info[:monthlyAwardAmount] ? symbolized_info[:monthlyAwardAmount][:value] : 0

        # Don't return chapter35EligibilityDateTime
        # It's not currently (June 2023) used on the frontend, and in fact causes problems
        transformed_info
          .merge({ monthlyAwardAmount: monthly_award_amount })
          .except(:chapter35EligibilityDateTime)
      end

      def create_invalid_type_error(letter_type)
        error = Common::Exceptions::BadRequest.new
        error.source = "Invalid letter type: Letter type of #{letter_type.downcase} is not one of the expected options"

        error
      end

      def validate_downloadable_letter_type(letter_type)
        unless LETTER_TYPES.include? letter_type.downcase
          raise create_invalid_type_error(letter_type.downcase)
        end
      end
    end
  end
end
