# frozen_string_literal: true

module Sidekiq
  module Form526HistoricalDataExporter
    class Exporter

      def initialize(batch_size, data = [])
        @batch_size = batch_size
        @data = data
      end

      # add a basic method for testing
      def print_to_stdout!
        all = []
        batches = Form526Submission.select(:id, :created_at, :encrypted_kms_key, :form_json_ciphertext, :submitted_claim_id).find_in_batches(batch_size: @batch_size)
        batches.each do |batch|
          batch.each do |submission|
            all << [submission.id, submission.submitted_claim_id, submission.created_at, submission.form_json]
          end
        end
        puts all.size
        puts all.first
      end

      def process!
        # # do useful data stuff here, for now just pass
      end
    end
  end
end