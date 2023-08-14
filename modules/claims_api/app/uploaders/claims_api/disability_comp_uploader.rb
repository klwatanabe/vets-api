# frozen_string_literal: true

module ClaimsApi
  class DisabilityCompUploader < ClaimsApi::BaseUploader
    def location
      'disability_compensation'
    end
  end
end
