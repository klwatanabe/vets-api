# frozen_string_literal: true

require 'sidekiq'
require 'claims_api/claim_logger'
require 'claims_api/v2/disability_compensation_pdf_mapper'
require 'pdf_generator_service/pdf_client'

module ClaimsApi
  class DisabilityCompPdfGenerator
    include Sidekiq::Worker
    include SentryLogging

    def perform(claim, target_veteran)
      debugger
      ClaimsApi::Logger.log('dis_comp_pdf_generator', claim_id: claim.id, detail: '526EZ PDF generator started.')

      pdf_data = get_pdf_data
      pdf_mapper_service(claim.form_attributes, pdf_data, target_veteran).map_claim

      generate_526_pdf(pdf_data)
      case
      when pdf.empty?
        ClaimsApi::Logger.log('dis_comp_pdf_generator', claim_id: auto_claim.id, detail: '526EZ PDF generator failed.')
      when pdf
        # docker = ClaimsApi::DockerContainer.perform_async
        # @uploader ||= ClaimsApi::SupportingDocumentUploader.new(id)
      end
    end

    private
    
    def pdf_mapper_service(auto_claim, pdf_data, target_veteran)
      ClaimsApi::V2::DisabilityCompensationPdfMapper.new(auto_claim, pdf_data, target_veteran)
    end

    def get_pdf_data
      {
        data: {}
      }
    end


    def generate_526_pdf(pdf_data)
      pdf_data[:data] = pdf_data[:data][:attributes]
      client = PDFClient.new(pdf_data.to_json)
      client.generate_pdf
    end
  end
end