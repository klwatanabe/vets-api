# frozen_string_literal: true

require 'common/file_helpers'
require 'pdf_fill/filler'

# rubocop:disable Metrics/ModuleLength
module AppealsApi
  module PdfDownloads
    extend ActiveSupport::Concern

    included do
      def render_appeal_pdf_download(appeal, filename)
        return render_pdf_download_expired(appeal) if expired?(appeal)

        return render_pdf_download_unauthorized unless download_authorized?(appeal)

        return render_pdf_download_not_ready(appeal) unless submitted?(appeal)

        pdf_path = PdfDownloads.watermark(
          AppealsApi::PdfConstruction::Generator.new(appeal, pdf_version: appeal.pdf_version).generate,
          filename
        )

        send_file(pdf_path, type: 'application/pdf; charset=utf-8', filename:)
      end
    end

    # Creates a copy of the input PDF with a watermark on each page
    def self.watermark(input_path, output_path = "#{Common::FileHelpers.random_file_path}.pdf")
      num_pages = PDF::Reader.new(input_path).pages.length
      pdftk = PdfFill::Filler::PDF_FORMS
      stamp_path = "#{Common::FileHelpers.random_file_path}-watermark.pdf"

      Prawn::Document.generate(stamp_path, margin: [30, 30]) do |pdf|
        num_pages.times do
          pdf.image WATERMARK_PATH, fit: [pdf.bounds.width, pdf.bounds.height], position: :center, vposition: :center
          pdf.start_new_page # Final extra page won't be added to output
        end
      end

      pdftk.multistamp(input_path, stamp_path, output_path)
      FileUtils.rm_f(stamp_path)

      output_path
    end

    UNSUBMITTED_STATUSES = %w[pending submitting error].freeze
    WATERMARK_PATH = AppealsApi::Engine.root.join('config', 'images', 'va_seal.png')

    def download_authorized?(appeal)
      return false unless (header_icn = request.headers['X-VA-ICN'])

      if appeal.veteran_icn.present?
        return appeal.veteran_icn == header_icn
      elsif (appeal_icn = appeal.auth_headers['X-VA-ICN'])
        return appeal_icn == header_icn
      end

      header_mpi_profile = MPI::Service.new.find_profile_by_identifier(
        identifier: header_icn,
        identifier_type: 'ICN'
      ).profile

      if (appeal_ssn = appeal.auth_headers['X-VA-SSN'])
        return appeal_ssn == header_mpi_profile.ssn
      end

      false
    end

    def submitted?(appeal)
      UNSUBMITTED_STATUSES.exclude?(appeal.status) && appeal.pdf_version.present?
    end

    def expired?(appeal)
      appeal.class.pii_expunge_policy.exists?(appeal.id) || appeal.auth_headers.blank?
    end

    def render_pdf_download_unauthorized
      render(
        status: :unauthorized,
        json: {
          errors: [
            {
              code: '401',
              detail: I18n.t('appeals_api.errors.unauthorized_pii_headers'),
              status: '401',
              title: 'PDF download unauthorized'
            }
          ]
        }
      )
    end

    def render_pdf_download_not_ready(appeal)
      msg_key = if appeal.status == 'error'
                  'appeals_api.errors.pdf_download_in_error'
                else
                  'appeals_api.errors.pdf_download_not_ready'
                end

      render(
        status: :unprocessable_entity,
        json: {
          errors: [
            {
              code: '422',
              detail: I18n.t(msg_key, type: appeal.class.name.demodulize, id: appeal.id),
              status: '422',
              title: 'PDF download not ready'
            }
          ]
        }
      )
    end

    def render_pdf_download_expired(appeal)
      render(
        status: :gone,
        json: {
          errors: [
            {
              code: '410',
              detail: I18n.t(
                'appeals_api.errors.pdf_download_expired',
                type: appeal.class.name.demodulize,
                id: appeal.id
              ),
              status: '410',
              title: 'PDF download expired'
            }
          ]
        }
      )
    end
  end
end
# rubocop:enable Metrics/ModuleLength
