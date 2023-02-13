# frozen_string_literal: true

require 'common/client/configuration/rest'
require 'common/client/middleware/request/camelcase'
require 'common/client/middleware/request/multipart_request'
require 'common/client/middleware/response/json_parser'
require 'common/client/middleware/response/raise_error'
require 'common/client/middleware/response/mhv_errors'
require 'common/client/middleware/response/snakecase'
require 'sm/middleware/response/sm_parser'

module MedicalRecords
  ##
  # HTTP client configuration for {MedicalRecords::Client}
  #
  class Configuration < Common::Client::Configuration::REST
    ##
    # @return [String] Base path for dependent URLs
    #
    def base_path
      "#{Settings.mhv.mr.host}/fhir/"
    end

    # ##
    # # Creates a connection with middleware for mapping errors, parsing XML, and
    # # adding breakers functionality
    # #
    # # @see SM::Middleware::Response::SMParser
    # # @return [Faraday::Connection] a Faraday connection instance
    # #
    # def connection
    #   Faraday.new(base_path, headers: base_request_headers, request: request_options) do |conn|
    #     conn.adapter Faraday.default_adapter
    #   end
    # end
  end
end
