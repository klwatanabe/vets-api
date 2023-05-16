# frozen_string_literal: true

module IncomeLimits
  class StdStateImport
    include Sidekiq::Worker
    def perform
      csv_url = 'https://sitewide-public-websites-income-limits-data.s3-us-gov-west-1.amazonaws.com/std_state.csv'
      data = URI.open(csv_url).read
      
      CSV.parse(data, headers: true) do |row|
        created = DateTime.strptime(row['CREATED'], '%m/%d/%Y %l:%M:%S.%N %p').to_s
        updated = DateTime.strptime(row['UPDATED'], '%m/%d/%Y %l:%M:%S.%N %p').to_s if row['UPDATED']
        StdState.create!(
          id: row['ID'].to_i,
          name: row['NAME'],
          postal_name: row['POSTALNAME'],
          fips_code: row['FIPSCODE'].to_i,
          country_id: row['COUNTRY_ID'].to_i,
          version: row['VERSION'].to_i,
          created: created,
          updated: updated,
          created_by: row['CREATEDBY'],
          updated_by: row['UPDATEDBY']
        )
      end
    end
  end
end