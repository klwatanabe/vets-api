# frozen_string_literal: true

require 'common/models/base'

module Avs
  class V0::AfterVisitSummary < Common::Base
    include ActiveModel::Serializers::JSON

    attribute :id, String
    attribute :icn, String
    attribute :appointmentIens, Array
    attribute :generatedDate, String

    def initialize(data)
      super(data)
      # set_attributes(data)

      self.id = data['sid']
      self.icn = data['data']['patientInfo']['icn']
      self.appointmentIens = data['appointmentIens']
      self.generatedDate = data['generatedDate']
    end

    private

    def set_attributes(data)
      data['attributes'].each_key do |key|
        self[key] = data['attributes'][key] if attributes.include?(key.to_sym)
      end
    end
  end
end
