# frozen_string_literal: true

require 'sidekiq/form526_historical_data_exporter/exporter'

module Sidekiq
  module Form526HistoricalDataExporter
    class Form526BackgroundDataJob
      include Sidekiq::Worker

      def perform(b_size)
        Exporter.new(b_size).print_to_stdout
      end
    end