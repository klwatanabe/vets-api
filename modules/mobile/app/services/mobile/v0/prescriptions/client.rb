# frozen_string_literal: true

require 'common/client/base'
require 'common/client/concerns/mhv_session_based_client'
require 'rx/client'
require_relative 'configuration'

module Mobile
  module V0
    module Rx
      class Client < ::Rx::Client
        configuration Mobile::V0::Rx::Configuration
        client_session ::Rx::ClientSession
      end
    end
  end
end
