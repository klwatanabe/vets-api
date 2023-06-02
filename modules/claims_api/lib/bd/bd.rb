# frozen_string_literal: true

module ClaimsApi
  ##
  # Class to interact with the BRD API
  #
  # Takes an optional request parameter
  # @param [] rails request object
  class BD
    def initialize(request = nil)
      @request = request
    end

    ##
    # UPload document of mapped claim
    #
    # @return success or failure
    def documents(claim)
      debugger
      body = transform_claim(claim)
      client.post('documents', body: body)
    end

    def transform_claim(claim)
      file = File.open("data.pdf", w) {|f| f.write("#{claim.form_data}") }

      data = {
        trackedItems: ['1', '2'], # list of tracked item ids
        systemName: 'va.gov',
        docType: 'L533',
        fileNumber: claim.veteran_icn, # veteran icn, ssn or vbms file number
        claimId: claim.id, # int
        fileName: file
      }
    end

    private

    def client
      base_name = if !Settings.brd&.base_name.nil?
                    Settings.brd.base_name
                  elsif @request&.host_with_port.nil?
                    'api.va.gov/services'
                  else
                    "#{@request&.host_with_port}/services"
                  end

      api_key = Settings.brd&.api_key || ENV.fetch('BRD_API_KEY', '')
      raise StandardError, 'BRD api_key missing' if api_key.blank?

      Faraday.new("https://#{base_name}/benefits-documents/v1",
                  # Disable SSL for (localhost) testing
                  ssl: { verify: Settings.brd&.ssl != false },
                  headers: { 'apiKey' => api_key }) do |f|
        f.request :json
        f.response :raise_error
        f.response :json, parser_options: { symbolize_names: true }
        f.adapter Faraday.default_adapter
      end
    end
  end
end
