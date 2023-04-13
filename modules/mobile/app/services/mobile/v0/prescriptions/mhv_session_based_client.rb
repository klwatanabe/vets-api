# frozen_string_literal: true
require 'common/client/concerns/mhv_session_based_client'

module Mobile
      ##
      # Module mixin for overriding session logic when making MHV client connections
      #
      # @see BB::Client
      # @see Rx::Client
      # @see SM::Client
      # @see MHVLogging::Client
      #
      # @!attribute [r] session
      #   @return [Hash] a hash containing session information
      #
      module MHVSessionBasedClient
        include Common::Client::Concerns::MHVSessionBasedClient

        MOBILE_REQUEST_HEADERS = {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Mobile Agent'
        }.freeze

        def token_headers
          binding.pry
          config.MOBILE_REQUEST_HEADERS.merge('Token' => session.token)
        end

        def auth_headers
          config.MOBILE_REQUEST_HEADERS.merge('appToken' => config.app_token, 'mhvCorrelationId' => session.user_id.to_s)
        end
      end
    end
