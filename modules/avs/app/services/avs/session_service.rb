# frozen_string_literal: true

module Avs
  class SessionService < Avs::BaseService
    attr_accessor :user

    def initialize(user)
      @user = user
      super()
    end

    private

    def perform(method, path, params, headers = nil, options = nil)
      super(method, path, params, headers, options)
    end

    def headers
      {
        # TODO: adjust according to AVS service reqs.
        'X-AVS-JWT' => user_service.session(@user)
      }
    end

    def user_service
      @user_service ||= Avs::UserService.new
    end
  end
end
