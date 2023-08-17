# frozen_string_literal: true

require 'faraday'

module ClaimsApi
  ##
  # Class to interact with the BRD API
  #
  # Takes an optional request parameter
  # @param [] rails request object
  class BD
    def initialize(multipart: false, request: nil)
      @request = request
      @multipart = multipart
    end

    ##
    # Search documents by claim and file number
    #
    # @return Documents list
    def search(claim_id, file_number)
      body = { data: { claimId: claim_id, fileNumber: file_number } }
      ClaimsApi::Logger.log('benefits_documents',
                            detail: "calling benefits documents search for claimId #{claim_id}")
      client.post('documents/search', body)&.body
    rescue => e
      ClaimsApi::Logger.log('benefits_documents',
                            detail: "/search failure for claimId #{claim_id}, #{e.message}")
      {}
    end

    ##
    # Upload document of mapped claim
    #
    # @return success or failure
    def upload(claim, pdf_path, file_number)
      body = generate_upload_body(claim, pdf_path, file_number)
      client.post('documents', body)&.body
    end

    ##
    # Generate form body to upload a document
    #
    # @return {paramenters, file}
    def generate_upload_body(claim, pdf_path, file_number)
      payload = {}
      data = {
        data: {
          systemName: 'va.gov',
          docType: 'L122',
          claimId: claim.evss_id,
          fileNumber: file_number,
          fileName: File.basename(pdf_path),
          trackedItemIds: []
        }
      }
      payload[:parameters] = data
      fn = Tempfile.new('params')
      File.write(fn, data.to_json)
      payload[:parameters] = Faraday::UploadIO.new(fn, 'application/json')
      payload[:file] = Faraday::UploadIO.new(pdf_path, 'application/pdf')
      payload
    end

    private

    ##
    # Configure Faraday base class (and do auth)
    #
    # @return Faraday client
    def client
      base_name = if !Settings.bd&.base_name.nil?
                    Settings.bd.base_name
                  elsif @request&.host_with_port.nil?
                    'api.va.gov/services'
                  else
                    "#{@request&.host_with_port}/services"
                  end

      @token ||= ClaimsApi::V2::BenefitsDocuments::Service.new.get_auth_token
      raise StandardError, 'Benefits Docs token missing' if @token.blank?

      Faraday.new("https://#{base_name}/benefits-documents/v1",
                  headers: { 'Authorization' => "Bearer #{@token}" }) do |f|
        f.request @multipart ? :multipart : :json
        f.response :raise_error
        f.response :json, parser_options: { symbolize_names: true }
        f.adapter Faraday.default_adapter
      end
    end
  end
end
