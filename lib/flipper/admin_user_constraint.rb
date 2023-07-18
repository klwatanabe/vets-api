# frozen_string_literal: true

module Flipper
  class AdminUserConstraint
    def self.matches?(request)
      # puts 'request_path: ' + request.method + ' ' + request.path

      if request.session[:flipper_user].present?
        user = request.session[:flipper_user]
        RequestStore.store[:flipper_user_email_for_log] = user&.email
        authorize(user)

        return true
      end

      return true if request.method == 'GET' && request.path.exclude?('/callback')

      authenticate(request)
    end

    def self.authenticate(request)
      RequestStore.store[:flipper_user_email_for_log] = nil
      warden = request.env['warden']
      warden.authenticate!(scope: :flipper)
    end

    def self.authorize(user)
      org_name = Settings.flipper.github_organization
      team_id = Settings.flipper.github_team

      RequestStore.store[:flipper_authorized] = user.organization_member?(org_name) && user.team_member?(team_id)
    end
  end
end
