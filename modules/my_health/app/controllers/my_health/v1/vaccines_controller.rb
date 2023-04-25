# frozen_string_literal: true

module MyHealth
  module V1
    class VaccinesController < MRController
      def index
        p "In VaccinesController index!"
      end

      def show
        vaccine_id = params[:id].try(:to_i)
        client = FHIR::Client.new("http://hapi.fhir.org/baseR4/").tap do |client|
          client.use_r4
          client.default_json
          client.set_no_auth
          client.use_minimal_preference
        end
        resource = client.read(FHIR::Immunization, vaccine_id).resource
        raise Common::Exceptions::InternalServerError if resource.blank?
        render json: resource.to_json
      end

      def pdf
        vaccine_id = params[:id]
        vaccines_list = vaccine_id ? [1] : [*0...9]
        filename = vaccine_id ? 'tmp/vaccine.pdf' : 'tmp/vaccines.pdf'

        MyHealth::PdfConstruction::Generator.new(filename, vaccines_list).make_vaccines_pdf

        pdf_file = File.open(filename)
        base64 = Base64.encode64(pdf_file.read)
        response = { pdf: base64 }
        render json: response
      end
    end
  end
end
