# frozen_string_literal: true

require 'common/exceptions'
require 'jsonapi/parser'
require 'claims_api/v2/disability_compensation_validation'
require 'claims_api/v2/disability_compensation_pdf_mapper'
require 'claims_api/v2/disability_compensation_evss_mapper'
require 'evss_service/base'

module ClaimsApi
  module V2
    module Veterans
      class DisabilityCompensationController < ClaimsApi::V2::Veterans::Base
        include ClaimsApi::V2::DisabilityCompensationValidation

        FORM_NUMBER = '526'

        before_action :verify_access!
        before_action :shared_validation, only: %i[submit validate]

        def submit
          auto_claim = ClaimsApi::AutoEstablishedClaim.create(
            status: ClaimsApi::AutoEstablishedClaim::PENDING,
            auth_headers:,
            form_data: form_attributes,
            cid: token.payload['cid'],
            veteran_icn: target_veteran.mpi.icn
          )
          pdf_data = get_pdf_data
          pdf_mapper_service(form_attributes, pdf_data, target_veteran).map_claim

          # evss_data = evss_mapper_service(auto_claim).map_claim
          # evss_claim = evss_service.submit(auto_claim, evss_data)

          render json: auto_claim
        end

        def validate
          render json: valid_526_response
        end

        def attachments; end

        def get_pdf
          # Returns filled out 526EZ form as PDF
        end

        private

        def shared_validation
          validate_json_schema
          validate_form_526_submission_values!
        end

        def valid_526_response
          {
            data: {
              type: 'claims_api_auto_established_claim_validation',
              attributes: {
                status: 'valid'
              }
            }
          }
        end

        def pdf_mapper_service(auto_claim, pdf_data, target_veteran)
          ClaimsApi::V2::DisabilityCompensationPdfMapper.new(auto_claim, pdf_data, target_veteran)
        end

        def evss_mapper_service(auto_claim)
          ClaimsApi::V2::DisabilityCompensationEvssMapper.new(auto_claim)
        end

        def get_pdf_data
          {
            data: {
              attributes:
                {}
            }
          }
        end

        def evss_service
          ClaimsApi::EVSSService::Base.new(request)
        end
      end
    end
  end
end
