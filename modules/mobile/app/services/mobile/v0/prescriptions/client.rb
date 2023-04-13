# frozen_string_literal: true

require 'common/client/base'
require 'rx/client'
require_relative 'configuration'
require_relative 'mhv_session_based_client'

module Mobile
  module V0
    module Rx
      class Client < ::Rx::Client
        include Mobile::MHVSessionBasedClient

        configuration Mobile::V0::Rx::Configuration
        client_session ::Rx::ClientSession
      end
    end
  end
end
