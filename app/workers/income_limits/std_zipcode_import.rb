# frozen_string_literal: true

require 'open-uri'
require 'csv'

module IncomeLimits
  class StdZipcodeImport
    include Sidekiq::Worker

    def perform
      csv_url = 'https://sitewide-public-websites-income-limits-data.s3-us-gov-west-1.amazonaws.com/std_zipcode.csv'
      data = URI.open(csv_url).read
      CSV.parse(data, headers: true) do |row|
        created = DateTime.strptime(row['CREATED'], '%m/%d/%Y %l:%M:%S.%N %p').to_s
        updated = DateTime.strptime(row['UPDATED'], '%m/%d/%Y %l:%M:%S.%N %p').to_s if row['UPDATED']
        std_zipcode = StdZipcode.find_or_initialize_by(id: row['ID'].to_i)
        std_zipcode.assign_attributes(
          zip_code: row['ZIPCODE'].to_i,
          zip_classification_id: row['ZIPCLASSIFICATION_ID']&.to_i,
          preferred_zip_place_id: row['PREFERREDZIPPLACE_ID']&.to_i,
          state_id: row['STATE_ID'].to_i,
          county_number: row['COUNTYNUMBER'].to_i,
          version: row['VERSION'].to_i,
          created:,
          updated:,
          created_by: row['CREATEDBY'],
          updated_by: row['UPDATEDBY']
        )

        std_zipcode.save!
      end
    end
  end
end
