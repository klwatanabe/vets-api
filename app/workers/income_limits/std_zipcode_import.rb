# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

require 'net/http'
require 'csv'

module IncomeLimits
  class StdZipcodeImport
    include Sidekiq::Worker

    def perform
      csv_url = 'https://sitewide-public-websites-income-limits-data.s3-us-gov-west-1.amazonaws.com/std_zipcode.csv'
      uri = URI(csv_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      if response.code == '200'
        data = response.body
        CSV.parse(data, headers: true) do |row|
          created = DateTime.strptime(row['CREATED'], '%m/%d/%Y %l:%M:%S.%N %p').to_s
          updated = DateTime.strptime(row['UPDATED'], '%m/%d/%Y %l:%M:%S.%N %p').to_s if row['UPDATED']
          std_zipcode = StdZipcode.find_by(id: row['ID'].to_i)
          next if std_zipcode

          std_zipcode = StdZipcode.new(
            id: row['ID'].to_i,
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
      else
        raise "Failed to fetch CSV data. Response code: #{response.code}"
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength
