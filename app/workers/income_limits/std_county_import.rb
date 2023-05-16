# frozen_string_literal: true
require 'open-uri'
require 'csv'

module IncomeLimits
  class StdCountyImport
    include Sidekiq::Worker

    def perform
      csv_url = 'https://sitewide-public-websites-income-limits-data.s3-us-gov-west-1.amazonaws.com/std_county.csv'
      data = URI.open(csv_url).read
      
      CSV.parse(data, headers: true) do |row|
        created = DateTime.strptime(row['CREATED'], '%m/%d/%Y %l:%M:%S.%N %p').to_s
        updated = DateTime.strptime(row['UPDATED'], '%m/%d/%Y %l:%M:%S.%N %p').to_s if row['UPDATED']
        StdCounty.create!(
          id: row['ID'].to_i,
          name: row['NAME'].to_s,
          county_number: row['COUNTYNUMBER'].to_i,
          description: row['DESCRIPTION'],
          state_id: row['STATE_ID'].to_i,
          version: row['VERSION'].to_i,
          created: created,
          updated: updated,
          created_by: row['CREATEDBY'].to_s,
          updated_by: row['UPDATEDBY'].to_s
        )
      end
    end
  end
end
