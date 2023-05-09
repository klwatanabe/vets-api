# frozen_string_literal: true

require 'aws-sdk-s3'
require 'csv'
class GmtThresholdCsvImporter
  include Sidekiq::Worker
  def perform(bucket, key)
    s3 = Aws::S3::Resource.new(region: 'us-gov-west-1')
    obj = s3.bucket(bucket).object(key)
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
        msaname: row['MSANAME'],
        version: row['VERSION'].to_i,
        created: row['CREATED'],
        updated: row['UPDATED'],
        createdby: row['CREATEDBY'],
        updatedby: row['UPDATEDBY']
      )
    end
  end
end











Jot something down








