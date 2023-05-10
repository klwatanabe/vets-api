# frozen_string_literal: true

module IncomeLimits
  class StdStateImport
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
      
      CSV.parse(data, headers: true) do |row|
        StdState.create!(
          id: row['ID'].to_i,
          name: row['NAME'],
          postal_name: row['POSTALNAME'],
          fips_code: row['FIPSCODE'].to_i,
          country_id: row['COUNTRY_ID'].to_i,
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