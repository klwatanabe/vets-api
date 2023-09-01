# frozen_string_literal: true

require 'lighthouse/letters_generator/service'
require 'lighthouse/letters_generator/service_error'
require 'lighthouse/letters_generator/veteran_sponsor_resolver'
require 'evss/letters/download_service'

module V0
  class LettersGeneratorController < ApplicationController
    before_action { authorize :lighthouse, :access? }
    before_action { authorize :evss, :access_letters? }

    before_action :validate_letter_type, only: %i[download]
    Raven.tags_context(team: 'benefits-claim-appeal-status', feature: 'letters-generator')
    DOWNLOAD_PARAMS = %i[
      id
      format
      military_service
      service_connected_disabilities
      service_connected_evaluation
      non_service_connected_pension
      monthly_award
      unemployable
      special_monthly_compensation
      adapted_housing
      chapter35_eligibility
      death_result_of_disability
      survivors_award
      letters_generator
    ].freeze

    def index
      response = service.get_eligible_letter_types(@current_user.icn)
      render json: response
    end

    def download
      if Flipper.enabled?(:bcas_letters_use_lighthouse_download)
        lh_download
      else
        evss_download
      end
    end

    def lh_download
      permitted_params = params.permit(DOWNLOAD_PARAMS)
      letter_options =
        permitted_params.to_h
                        .except('id')
                        .transform_values { |v| ActiveModel::Type::Boolean.new.cast(v) }
                        .transform_keys { |k| k.camelize(:lower) }

      # Throws an error if the current user is a dependent but has no sponsor
      icn = Lighthouse::LettersGenerator::VeteranSponsorResolver.get_icn(@current_user)
      response = service.download_letter(icn, params[:id], letter_options)
      send_data response,
                filename: "#{params[:id]}.pdf",
                type: 'application/pdf',
                disposition: 'attachment'
    end

    def evss_download
      unless EVSS::Letters::Letter::LETTER_TYPES.include? params[:id]
        Raven.tags_context(team: 'benefits-memorial-1') # tag sentry logs with team name
        raise Common::Exceptions::ParameterMissing, 'letter_type', "#{params[:id]} is not a valid letter type"
      end

      response = evss_download_service.download_letter(params[:id], request.body.string)
      send_data response,
                filename: "#{params[:id]}.pdf",
                type: 'application/pdf',
                disposition: 'attachment'
    end

    def beneficiary
      response = service.get_benefit_information(@current_user.icn)
      render json: response
    end

    private

    def validate_letter_type
      unless service.valid_type?(params[:id])
        raise Common::Exceptions::BadRequest.new(
          {
            detail: "Letter type of #{params[:id]} is not one of the expected options",
            source: self.class.name
          }
        )
      end
    end

    def service
      @service ||= Lighthouse::LettersGenerator::Service.new
    end

    def evss_download_service
      EVSS::Letters::DownloadService.new(@current_user)
    end
  end
end
