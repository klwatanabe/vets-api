# frozen_string_literal: true

module Avs
  class SessionService < Avs::BaseService
    attr_accessor :user

    def initialize(user)
      @user = user
    end

    private

    def perform(method, path, params, headers = nil, options = nil)
      response = super(method, path, params, headers, options)
      # user_service.extend_session(@user.account_uuid)
      response
    end

    def headers
      {
        # TODO: adjust according to AVS service reqs.
        'X-AVS-JWT' => user_service.session(@user),
      }
    end

    def user_service
      @user_service ||= Avs::UserService.new
    end
  end
end
