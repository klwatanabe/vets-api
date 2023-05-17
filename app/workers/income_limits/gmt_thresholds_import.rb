# frozen_string_literal: true

require 'aws-sdk-s3'
require 'csv'
module IncomeLimits
  class GmtThresholdsImport
    include Sidekiq::Worker

    def perform
      csv_url = 'https://sitewide-public-websites-income-limits-data.s3-us-gov-west-1.amazonaws.com/std_gmtthresholds.csv'
      data = URI.open(csv_url).read

      CSV.parse(data, headers: true) do |row|
        created = DateTime.strptime(row['CREATED'], '%m/%d/%Y %l:%M:%S.%N %p').to_s
        updated = DateTime.strptime(row['UPDATED'], '%m/%d/%Y %l:%M:%S.%N %p').to_s if row['UPDATED']
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
          created:,
          updated:,
          created_by: row['CREATEDBY'],
          updated_by: row['UPDATEDBY']
        )
      end
    end
  end
end
