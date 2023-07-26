# frozen_string_literal: true

require 'common/exceptions'

module Avs
  class UserService < Avs::BaseService
    def session(user)
      # FIXME: this is a hack to get around the fact that we don't have a user object.
      return if user.nil?

      cached = cached_by_account_uuid(user.account_uuid)
      return cached.token if cached

      new_session_token(user)
    end

    private

    def cached_by_account_uuid(account_uuid)
      SessionStore.find(account_uuid)
    end

    def save_session!(account_uuid, token)
      session_store = SessionStore.new(
        account_uuid:,
        token:,
        unix_created_at: Time.now.utc.to_i
      )
      session_store.save
      session_store.expire(ttl_duration_from_token(token))
      token
    end

    def new_session_token(user)
      # TODO: implement me.
    end

    def headers
      { 'Accept' => 'text/plain', 'Content-Type' => 'text/plain', 'Referer' => referrer }
    end

    def refresh_headers(account_uuid)
      {
        'Referer' => referrer,
        'X-VAMF-JWT' => cached_by_account_uuid(account_uuid).token,
        'X-Request-ID' => RequestStore.store['request_id']
      }
    end

    def ttl_duration_from_token(token)
      # token expiry with 45 second buffer to match SessionStore model TTL buffer
      Time.at(decoded_token(token)['exp']).utc.to_i - Time.now.utc.to_i - 45
    end

    def decoded_token(token)
      JWT.decode(token, nil, false).first
    end

    def body?(response)
      response&.body && response.body.present?
    end
  end
end
