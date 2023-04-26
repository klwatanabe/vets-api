# frozen_string_literal: true

require 'common/exceptions'
require 'jsonapi/parser'
require 'claims_api/v2/concerns/disabilitity_compensation/validation'

module ClaimsApi
  module V2
    module Veterans
      class DisabilityCompensationController < ClaimsApi::V2::ApplicationController
        include ClaimsApi::V2::Concerns::DisabilityCompensation::Validation

        FORM_NUMBER = '526'

        def submit
          render json: { status: 200}
        end

        def validate; end

        def attachments; end
      end
    end
  end
end
