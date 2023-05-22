# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

require 'net/http'
require 'csv'

module IncomeLimits
  class StdStateImport
    include Sidekiq::Worker

    def perform
      csv_url = 'https://sitewide-public-websites-income-limits-data.s3-us-gov-west-1.amazonaws.com/std_state.csv'
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
          std_state = StdState.find_or_initialize_by(id: row['ID'].to_i)
          next if std_state

          std_state.assign_attributes(
            name: row['NAME'],
            postal_name: row['POSTALNAME'],
            fips_code: row['FIPSCODE'].to_i,
            country_id: row['COUNTRY_ID'].to_i,
            version: row['VERSION'].to_i,
            created:,
            updated:,
            created_by: row['CREATEDBY'],
            updated_by: row['UPDATEDBY']
          )
          std_state.save!
        end
      else
        raise "Failed to fetch CSV data. Response code: #{response.code}"
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength