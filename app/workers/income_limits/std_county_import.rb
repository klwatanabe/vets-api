# frozen_string_literal: true

module IncomeLimits
  class StdCountyImport
    include SideKiq::Worker

    S3_CLAIMS_RESOURCE_OPTIONS = {
      access_key_id: Settings.evss.s3.aws_access_key_id,
      secret_access_key: Settings.evss.s3.aws_secret_access_key,
      region: Settings.evss.s3.region
    }.freeze


    def perform(bucket, key)
      s3 = Aws::S3::Resource.new(region: 'us-gov-west-1')
      obj = s3.bucket(bucket).object(key)
      data = obj.get.body.read
      CSV.parse(data, headers: true) do |row|
        StdCounty.create!(
          id: row['id'].to_i,
          name: row['name'],
          county_number: row['countynumber'].to_i,
          description: row['description'],
          state_id: row['state_id'].to_i,
          version: row['version'].to_i,
          created: row['created'],
          updated: row['updated'],
          created_by: row['createdby'],
          updated_by: row['updatedby']
        )
      end
    end
  end
end
