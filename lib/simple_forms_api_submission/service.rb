# frozen_string_literal: true

require 'common/client/base'
require 'common/client/concerns/monitoring'
require 'common/client/errors'
require 'common/exceptions/forbidden'
require 'common/exceptions/schema_validation_errors'
require 'simple_forms_api_submission/configuration'

module SimpleFormsApiSubmission
  ##
  # Proxy Service for the Lighthouse Benefits Intake API Service
  #
  class Service < Common::Client::Base
    include SentryLogging
    include Common::Client::Concerns::Monitoring

    configuration SimpleFormsApiSubmission::Configuration

    def get_upload_location
      headers = {}
      request_body = {}
      perform :post, 'uploads', request_body, headers
    end

    def generate_tmp_metadata(metadata)
      Common::FileHelpers.generate_temp_file(metadata.to_s, "#{SecureRandom.hex}.SimpleFormsApi.metadata.json")
    end

    def get_upload_docs(file:, metadata:, attachments:)
      json_tmpfile = generate_tmp_metadata(metadata)
      file_name = File.basename(file)
      params = { metadata: Faraday::UploadIO.new(json_tmpfile, Mime[:json].to_s, 'metadata.json'),
                 content: Faraday::UploadIO.new(file, Mime[:pdf].to_s, file_name) }
      attachments.each.with_index do |attachment, i|
        params["attachment#{i + 1}".to_sym] = Faraday::UploadIO.new(attachment, Mime[:pdf].to_s, attachment)
      end
      [params, json_tmpfile]
    end

    def upload_doc(upload_url:, file:, metadata:, attachments: [])
      params, _json_tmpfile = get_upload_docs(file:, metadata:, attachments:)
      response = perform :put, upload_url, params, { 'Content-Type' => 'multipart/form-data' }

      raise response.body unless response.success?

      response
    end
  end
end
