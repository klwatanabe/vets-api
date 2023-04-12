# frozen_string_literal: true

require 'common/client/configuration/rest'
require 'common/client/middleware/request/camelcase'
require 'common/client/middleware/response/json_parser'
require 'common/client/middleware/response/raise_error'
require 'common/client/middleware/response/mhv_errors'
require 'common/client/middleware/response/snakecase'
require 'common/client/middleware/response/mhv_xml_html_errors'
require 'rx/middleware/response/rx_parser'
require 'rx/middleware/response/rx_failed_station'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'rx/configuration'

module Mobile
  module V0
    module Rx
      ##
      # HTTP client configuration for {Rx::Client}, sets the token, base path and a service name for breakers and metrics
      #
      class Configuration < ::Rx::Configuration
        MOBILE_REQUEST_HEADERS = {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Mobile Agent'
        }.freeze

        def connection
          Faraday.new(base_path, headers: MOBILE_REQUEST_HEADERS, request: request_options) do |conn|
            conn.use :breakers
            conn.request :json

            # Uncomment this if you want curl command equivalent or response output to log
            # conn.request(:curl, ::Logger.new($stdout), :warn) unless Rails.env.production?
            # conn.response(:logger, ::Logger.new($stdout), bodies: true) unless Rails.env.production?

            conn.response :betamocks if Settings.mhv.rx.mock
            conn.response :rx_failed_station
            conn.response :rx_parser
            conn.response :snakecase
            conn.response :raise_error, error_prefix: service_name
            conn.response :mhv_errors
            conn.response :mhv_xml_html_errors
            conn.response :json_parser

            conn.adapter Faraday.default_adapter
          end
        end

        def parallel_connection
          Faraday.new(base_path, headers: MOBILE_REQUEST_HEADERS, request: request_options) do |conn|
            conn.use :breakers
            conn.request :camelcase
            conn.request :json

            # Uncomment this if you want curl command equivalent or response output to log
            # conn.request(:curl, ::Logger.new(STDOUT), :warn) unless Rails.env.production?
            # conn.response(:logger, ::Logger.new(STDOUT), bodies: true) unless Rails.env.production?

            conn.response :snakecase
            conn.response :raise_error, error_prefix: service_name
            conn.response :mhv_errors
            conn.response :json_parser

            conn.adapter :typhoeus
          end
        end
      end
    end
  end
end
