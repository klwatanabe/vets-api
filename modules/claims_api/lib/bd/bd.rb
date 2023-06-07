# frozen_string_literal: true
require 'faraday'
require 'faraday/multipart'

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
      @subdomain = "documents"
      body = transform_claim(claim)
      client.post('documents', body:)
    end

    def transform_claim(claim)
      @payload = {}
      parameters = 
      # {
      #   "data": {
      #     "systemName": 'va.gov',
      #     "docType": 'L533',
      #     "fileNumber": "#{claim.veteran_icn}",
      #     "claimId": claim.id,
      #     "fileName": "form_data.pdf"
      #   }
      # }
      {
        "data": {
          "systemName": "va.gov",
          "docType": "L122",
          "claimId": 600400688,
          "fileNumber": "796130115",
          "fileName": "form_data.pdf"
        }
      }
      file_path = File.join('tmp', 'benefits_docs', claim.id)
      FileUtils.mkdir_p(file_path) unless File.exist?(file_path)
      File.open(File.join(file_path, "form_data.pdf"), 'w') do |f|
        f.write(claim.form_data)
        f.close
      end
      FileUtils.mkdir_p(file_path) unless File.exist?(file_path)
      File.open(File.join(file_path, "parameters.json"), 'w') do |f|
        f.write(parameters)
        f.close
      end
      @payload[:file] = Faraday::Multipart::FilePart.new(File.join(file_path, "form_data.pdf"), 'text/x-ruby')
      @payload[:parameters] = Faraday::Multipart::FilePart.new(File.join(file_path, "parameters.json"), 'text/x-ruby')
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
                  
      token = "Bearer #{Settings.bd&.api_oauth_client_id}"
      raise StandardError, 'Benefits Docs api_oauth_client_id missing' if token.blank?
      # url = "https://#{base_name}/benefits-documents/v1/#{@subdomain}"
      url= "https://localhost:4451/benefits-documents/v1/documents"
      conn = Faraday.new(url,
                  # Disable SSL for (localhost) testing
                  ssl: { verify: false }, #Settings.brd&.ssl != false },
                  headers: { 'Authorization' => token }) do |f|
        f.request :multipart, :json
        f.response :raise_error
        f.response :json, parser_options: { symbolize_names: true }
        f.adapter Faraday.default_adapter
      end

      response = conn.post(url, @payload)
    end
  end
end

# $ bds search --env blue-staging --auth-token $TOKEN --claim-id 600400688 --file-number 796130115  | jq .
# {
#   "data": {
#     "documents": [
#       {
#         "documentId": "72ac1acd-8450-4d7a-a0b4-0cfde4e2d967",
#         "documentTypeLabel": "295",
#         "uploadedDateTime": "2023-05-03T00:49:23Z"
#       },
#       {
#         "documentId": "5bbc76c7-c508-4441-a592-26c7f1cae8bf",
#         "documentTypeLabel": "719",
#         "uploadedDateTime": "2023-05-03T17:33:22Z"
#       },
#       {
#         "documentId": "46c12063-0d98-48b2-80d2-6e9b9349d0a8",
#         "documentTypeLabel": "295",
#         "uploadedDateTime": "2023-05-03T00:49:15Z"
#       }
#     ]
#   }
# }
# curl -k "-HAuthorization: Bearer $TOKEN" -HContent-Type:multipart/form-data --form 'parameters=@/Users/alexwilson/Downloads/bd_test.json;type=application/json' --form 'file=@/Users/alexwilson/Downloads/test.pdf;type=application/pdf' https://localhost:4451/benefits-documents/v1/documents
# vets-api 1 % curl -k "-HAuthorization: Bearer $TOKEN" -HContent-Type:multipart/form-data --form 'parameters=@/Users/jennicastiehl/Oddball_Github/vets-api/tmp/benefits_docs/600400688/parameters.json;type=application/json' --form 'file=@/Users/jennicastiehl/Desktop/test.pdf;type=application/pdf' https://localhost:4451/benefits-documents/v1/documents
# {"data":{"success":true,"requestId":236}}%   