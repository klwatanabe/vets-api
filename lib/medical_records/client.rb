# frozen_string_literal: true

require 'common/client/base'
require 'common/client/concerns/mhv_session_based_client'
require 'sm/client_session'
require 'sm/configuration'

module MedicalRecords
  ##
  # Core class responsible for SM API interface operations
  #
  class Client < Common::Client::Base
    configuration MedicalRecords::Configuration

    def get_vaccine(vaccine_id)
      client = FHIR::Client.new("https://mhv-di-5-api.myhealth.va.gov/fhir/").tap do |client|
        client.use_r4
        client.default_json
        client.set_no_auth
        client.use_minimal_preference
      end
      patient = client.read(FHIR::Immunization, vaccine_id).resource
    end
  end
end
