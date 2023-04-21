# frozen_string_literal: true

module Sidekiq
  module Form526HistoricalDataExporter
    class Exporter
      def initialize(batch_size, start_id, end_id, data = [])
        @batch_size = batch_size.to_i
        @start_id = start_id
        @end_id = end_id
        @data = data
        @file_name = "/tmp/#{start_id}_#{end_id}.csv"
      end

      # have it take start and end Form526Submission IDs
      # pass them into the batch
      # write to file
      def write_to_file(content)
        File.write(@file_name, content)
      end

      # put file in s3
      def upload_to_s3!
        # fill in here
      end

      def process!
        all = []
        batches = Form526Submission.select(:id, :created_at, :encrypted_kms_key, :form_json_ciphertext,
                                           :submitted_claim_id).find_in_batches(batch_size: @batch_size, start: @start_id, finish: @end_id)
        batches.each do |batch|
          batch.each do |submission|
            all << [submission.id, submission.submitted_claim_id, submission.created_at, submission.form_json]
          end
        end
        # Fix to csv to get into something useable. Maybe yaml instead?
        # OR JSON!
        write_to_file(all.to_json)
        # puts all.to_json
      end
    end
  end
end
