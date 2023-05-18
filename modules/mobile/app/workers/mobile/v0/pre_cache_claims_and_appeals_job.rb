# frozen_string_literal: true

module Mobile
  module V0
    class PreCacheClaimsAndAppealsJob
      include Sidekiq::Worker

      sidekiq_options(retry: false)

      class MissingUserError < StandardError; end

      def perform(uuid)
        user = IAMUser.find(uuid) || User.find(uuid)
        raise MissingUserError, uuid unless user

        data, errors = claims_proxy(user).get_claims_and_appeals

        # the errors from this are worth looking into. i see a bunch of 404. not sure why that would happen
        # also see a 422 because the SSN in the header was not 9 digits.
        if errors.size.positive?
          Rails.logger.warn('mobile claims pre-cache set failed', user_uuid: uuid,
                                                                  errors:)
        else
          Mobile::V0::ClaimOverview.set_cached(user, data)
          # definitely not useful
          Rails.logger.info('mobile claims pre-cache set succeeded', user_uuid: uuid)
        end
      end

      private

      def claims_proxy(user)
        Mobile::V0::Claims::Proxy.new(user)
      end
    end
  end
end
