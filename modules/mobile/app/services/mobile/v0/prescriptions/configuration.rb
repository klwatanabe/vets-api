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
        self.user_agent = 'Mobile Agent'
        self.base_request_headers = {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json',
          'User-Agent' => user_agent
        }.freeze
      end
    end
  end
end
