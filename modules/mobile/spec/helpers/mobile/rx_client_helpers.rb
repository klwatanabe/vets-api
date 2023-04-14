# frozen_string_literal: true

# require 'rx/client'
require_relative '../../../app/services/mobile/v0/prescriptions/client'
module Mobile
  module Rx
    module ClientHelpers
      HOST = Settings.mhv.rx.host
      CONTENT_TYPE = 'application/json'
      APP_TOKEN = 'your-unique-app-token'
      TOKEN = 'GkuX2OZ4dCE=48xrH6ObGXZ45ZAg70LBahi7CjswZe8SZGKMUVFIU88='

      def authenticated_client
        Mobile::V0::Rx::Client.new(session: { user_id: 123,
                                              expires_at: Time.current + (60 * 60),
                                              token: TOKEN })
      end
    end
  end
end
