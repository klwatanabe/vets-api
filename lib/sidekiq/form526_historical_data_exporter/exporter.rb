# frozen_string_literal: true

module Sidekiq
  module Form526HistoricalDataExporter
    class Exporter
      def initialize(b_size, data = [])
        @bs = b_size.to_i
        @data = data
      end

      # add a basic method for testing
      def print_to_stdout!
        all = []
        batches = Form526Submission.select(:id, :created_at, :encrypted_kms_key, :form_json_ciphertext,
                                           :submitted_claim_id).find_in_batches(batch_size: @bs)
        batches.each do |batch|
          batch.each do |submission|
            all << [submission.id, submission.submitted_claim_id, submission.created_at, submission.form_json]
          end
        end
        puts all.first
      end

      def process!
        # find records in batches, save to enumerator, iterate over enumerator to decrypt each batch
      end
    end
  end
end
