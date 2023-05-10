# frozen_string_literal: true

module IncomeLimits
  class StdZipCodeImport
    include SideKiq::Worker

    S3_INCOME_LIMITS_OPTIONS = {
      access_key_id: Settings.income_limits.s3.aws_access_key_id,
      secret_access_key: Settings.income_limits.s3.aws_secret_access_key,
      region: Settings.income_limits.s3.region
    }.freeze


    def perform(bucket, key)
      s3 = Aws::S3::Resource.new(S3_INCOME_LIMITS_OPTIONS)
      obj = s3.bucket(Settings.income_limits.s3.bucket)
      data = obj.get.body.read

      StdZipcode.create!(
        id: row['ID'].to_i,
        zip_code: row['ZIPCODE'].to_i,
        zip_classification_id: row['ZIPCLASSIFICATION_ID']&.to_i,
        preferred_zip_place_id: row['PREFERREDZIPPLACE_ID']&.to_i,
        state_id: row['STATE_ID'].to_i,
        county_number: row['COUNTYNUMBER'].to_i,
        version: row['VERSION'].to_i,
        created: row['CREATED'],
        updated: row['UPDATED'],
        created_by: row['CREATEDBY'],
        updated_by: row['UPDATEDBY']
      )
    end
    end
  end
end