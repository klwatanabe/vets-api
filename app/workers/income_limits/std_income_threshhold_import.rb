# frozen_string_literal: true

module IncomeLimits
  class StdIncomeThresholdImport
    include SideKiq::Worker

    S3_CLAIMS_RESOURCE_OPTIONS = {
      access_key_id: Settings.evss.s3.aws_access_key_id,
      secret_access_key: Settings.evss.s3.aws_secret_access_key,
      region: Settings.evss.s3.region
    }.freeze


    def perform
      s3 = Aws::S3::Resource.new(S3_CLAIMS_RESOURCE_OPTIONS)
      failed_uploads = []
      sidekiq_retry_timeout = 21.days.ago

      %w[evss disability].each do |type|
        s3.bucket(Settings.evss.s3.bucket).objects(prefix: "#{type}_claim_documents").each do |object|
          if object.last_modified < sidekiq_retry_timeout
            failed_uploads << {
              file_path: object.key,
              last_modified: object.last_modified
            }
          end
        end
      end
    end
  end
end