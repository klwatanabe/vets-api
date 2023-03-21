# frozen_string_literal: true

require 'lighthouse/letters_generator/configuration'

module Lighthouse
  module LettersGenerator
    class Client < Common::Client::Base
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

      configuration Lighthouse::LettersGenerator::Configuration

      def initialize(conn = nil)
        super()
        @conn = if conn.nil?
                  config.connection
                else
                  conn
                end
      end

      def get_eligible_letter_types(icn)
        begin
          response = @conn.get('eligible-letters', { icn: icn })
        rescue Faraday::ClientError, Faraday::ServerError => e
          # rubocop:disable Style/RaiseArgs
          raise Lighthouse::LettersGenerator::ServiceError.new(e)
          # rubocop:enable Style/RaiseArgs
        end

        {
          letters: response.body['letters'],
          letter_destination: response.body['letterDestination']
        }
      end

      # TODO: repeated code #get_eligible_letter_types
      def get_benefit_information(icn)
        begin
          response = @conn.get('eligible-letters', { icn: icn })
        rescue Faraday::ClientError, Faraday::ServerError => e
          # rubocop:disable Style/RaiseArgs
          raise Lighthouse::LettersGenerator::ServiceError.new(e)
          # rubocop:enable Style/RaiseArgs
        end

        { benefitInformation: response.body['benefitInformation'] }
      end

      def download_letter(icn, letter_type, options = {})
        unless LETTER_TYPES.include? letter_type.downcase
          error = Lighthouse::LettersGenerator::ServiceError.new
          error.title = 'Invalid letter type'
          error.message = "Letter type of #{letter_type.downcase} is not one of the expected options"
          error.status = 400

          raise error
        end

        letter_options = options.select { |_, v| v == true }

        begin
          response = @conn.get("letters/#{letter_type}/letter", { icn: icn }.merge(letter_options))
        rescue Faraday::ClientError, Faraday::ServerError => e
          # rubocop:disable Style/RaiseArgs
          raise Lighthouse::LettersGenerator::ServiceError.new(e)
          # rubocop:enable Style/RaiseArgs
        end

        response.body
      end
    end
  end
end
