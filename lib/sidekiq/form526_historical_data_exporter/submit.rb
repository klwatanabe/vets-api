# frozen_string_literal: true

require 'sidekiq/form526_historical_data_exporter/exporter'

module Sidekiq
  module Form526HistoricalDataExporter
    class Form526BackgroundDataJobQueuer
      def initialize(chunk_size, batch_size) # add path to storage as argument? if so, add as attribute
        @batch_size = batch_size
        queue_chunks(chunk_submissions(chunk_size))
      end

      def chunk_submissions(chunk_size)
        Form526Submission.where('created_at >= ?', 3.years.ago).pluck(:id).each_slice(chunk_size)
      end

      def queue_chunks(chunks)
        chunks.each do |chunk|
          Form526BackgroundDataJob.perform(@batch_size, chunk.first, chunk.last) # add path to storage here
        end
      end
    end

    class Form526BackgroundDataJob
      include Sidekiq::Worker

      def self.perform(batch_size, start_id, end_id)
        Exporter.new(batch_size, start_id, end_id).process!
      end
    end
  end
end
