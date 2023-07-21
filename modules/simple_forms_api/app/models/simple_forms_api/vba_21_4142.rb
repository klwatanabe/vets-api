# frozen_string_literal: true

module SimpleFormsApi
  class VBA214142
    include Virtus.model(nullify_blank: true)

    attribute :data

    def initialize(data)
      @data = data
    end

    def metadata
      {
        'veteranFirstName' => @data.dig('veteran', 'full_name', 'first'),
        'veteranLastName' => @data.dig('veteran', 'full_name', 'last'),
        'fileNumber' => @data.dig('veteran', 'va_file_number').presence || @data.dig('veteran', 'ssn'),
        'zipCode' => @data.dig('veteran', 'address', 'postal_code'),
        'source' => 'VA Platform Digital Forms',
        'docType' => @data['form_number'],
        'businessLine' => 'CMP'
      }
    end

    def self.attachments(data)
      text = <<~STRING
        RELATIONSHIP TO VETERAN/CLAIMANT:  \
        #{data.dig('preparer_identification', 'relationship_to_veteran') ||
          data.dig('preparer_identification', 'other')} \
        #{data.dig('preparer_identification', 'preparer_full_name', 'first')} \
        #{data.dig('preparer_identification', 'preparer_full_name', 'middle')} \
        #{data.dig('preparer_identification', 'preparer_full_name', 'last')} \
        #{data.dig('preparer_identification', 'preparer_title')} \
        #{data.dig('preparer_identification', 'preparer_organization')} \
        #{data.dig('preparer_identification', 'preparer_address', 'street')} \
        #{data.dig('preparer_identification', 'preparer_address', 'street2')} \
        #{data.dig('preparer_identification', 'preparer_address', 'city')} \
        #{data.dig('preparer_identification', 'preparer_address', 'state')} \
        #{data.dig('preparer_identification', 'preparer_address', 'postal_code')} \
        #{data.dig('preparer_identification', 'court_appointment_info')}
      STRING
      pdf = Prawn::Document.new
      pdf.text text
      pdf.render_file("tmp/vba_21_4142-attachment-tmp.pdf")
      ["tmp/vba_21_4142-attachment-tmp.pdf"]
    end
  end
end
