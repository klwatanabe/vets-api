# frozen_string_literal: true

require 'common/models/redis_store'

module Avs
  class SessionStore < Common::RedisStore
    redis_store REDIS_CONFIG[:avs_session][:namespace]
    redis_ttl REDIS_CONFIG[:avs_session][:each_ttl]
    redis_key :account_uuid

    attribute :account_uuid, String
    attribute :token, String
  end
end
