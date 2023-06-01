# frozen_string_literal: true

module VAProfile
  module DemographicsAuthorizable
    extend ActiveSupport::Concern

    def legacy_auth_enabled?
      Flipper.enabled?(:profile_personal_info_authorization, @current_user)
    end

    def access?
      DemographicsPolicy.new(@current_user).access?
    end

    def legacy_access?
      DemographicsPolicy.new(@current_user).legacy_access?
    end

    def authorize_request!
      if legacy_auth_enabled?
        raise Common::Exceptions::Forbidden, detail: 'User does not have a valid CSP ID' unless legacy_access?
      else
        raise Common::Exceptions::Forbidden, detail: 'User does not login using a valid CSP' unless access?
      end
    end
  end
end
