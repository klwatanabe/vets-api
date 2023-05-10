# frozen_string_literal: true

require 'aws-sdk-s3'
require 'csv'
class GmtThresholdCsvImporter
  include Sidekiq::Worker
  
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
      GmtThreshold.create!(
        id: row['ID'].to_i,
        effective_year: row['EFFECTIVEYEAR'].to_i,
        state_name: row['STATENAME'],
        county_name: row['COUNTYNAME'],
        fips: row['FIPS'].to_i,
        trhd1: row['TRHD1'].to_i,
        trhd2: row['TRHD2'].to_i,
        trhd3: row['TRHD3'].to_i,
        trhd4: row['TRHD4'].to_i,
        trhd5: row['TRHD5'].to_i,
        trhd6: row['TRHD6'].to_i,
        trhd7: row['TRHD7'].to_i,
        trhd8: row['TRHD8'].to_i,
        msa: row['MSA'].to_i,
        msa_name: row['MSANAME'],
        version: row['VERSION'].to_i,
        created: row['CREATED'],
        updated: row['UPDATED'],
        created_by: row['CREATEDBY'],
        updated_by: row['UPDATEDBY']
      )
    end
  end
end