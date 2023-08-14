# frozen_string_literal: true

require 'sidekiq'
require 'claims_api/vbms_uploader'
require 'claims_api/poa_vbms_sidekiq'

module ClaimsApi
  class DisabilityCompVBMSUploadJob
    include Sidekiq::Worker

    # Uploads a 526EZ form to VBMS.
    #
    # @param claim_id [String] Unique identifier of the submitted claim
    def perform(claim_id)
      ClaimsApi::Logger.log('dis_comp_vbms_upload', claim_id: claim.id, detail: '526EZ VBMS upload started.')
      claim = ClaimsApi::AutoEstablishedClaim.find(claim_id)
      uploader = ClaimsApi::DisabilityCompUploader.new(claim_id)
      uploader.retrieve_from_store!(claim.file_data['filename'])
      file_path = fetch_file_path(uploader)
      upload_to_vbms(claim, file_path)
      # should we update BGS?
    rescue VBMS::Unknown
      rescue_vbms_error(claim)
    rescue Errno::ENOENT
      rescue_file_not_found(claim)
      raise
    rescue VBMS::FilenumberDoesNotExist
      rescue_vbms_file_number_not_found(claim)
      raise
    end

    def fetch_file_path(uploader)
      return uploader.file.file unless Settings.evss.s3.uploads_enabled

      stream = URI.parse(uploader.file.url).open
      # stream could be a Tempfile or a StringIO https://stackoverflow.com/a/23666898
      stream.try(:path) || stream_to_temp_file(stream).path
    end

    def stream_to_temp_file(stream, close_stream: true)
      file = Tempfile.new
      file.binmode
      file.write stream.read
      file
    ensure
      file.flush
      file.close
      stream.close if close_stream
    end
  end
end
