# frozen_string_literal: true

module Flipper
  class AdminUserConstraint
    def self.matches?(request)
      puts 'request_path: ' + request.method + ' ' + request.path

      return true if request.method == 'GET' && request.session[:flipper_user].present?

      if request.session[:flipper_user].blank?
        warden = request.env['warden']
        warden.authenticate!(scope: :flipper)
      end
      require 'pry'; binding.pry;
      github_organization_authenticate!(request.session[:flipper_user], Settings.flipper.github_organization)
      github_team_authenticate!(request.session[:flipper_user], Settings.flipper.github_team)

      true

      ## ______

      # puts 'request_path: ' + request.method + ' ' + request.path
      # # return true if request.method == 'GET'

      # return true if request.method == 'GET' && !request.path.include?('callback')

      # # return true if Rails.env.development? || request.method == 'GET'

      # warden = request.env['warden']
      # # request.session[:flipper_user] ||= warden.user

      # if request.session[:flipper_user].blank?
      #   warden.authenticate!(scope: :flipper)
      #   require 'pry'; binding.pry;
      #   request.session[:flipper_user] = warden.user
      # end
      # require 'pry'; binding.pry;

      # github_organization_authenticate!(request.session[:flipper_user], Settings.flipper.github_organization)
      # github_team_authenticate!(request.session[:flipper_user], Settings.flipper.github_team)

      # # we want to log who has made a change in Flipper::Instrumentation::EventSubscriber

      # false
    end

    # private

    def self.github_organization_authenticate!(user, name)
      unless user.organization_member?(name)
        raise Common::Exceptions::Forbidden, detail: "You don't have access to organization #{name}"
      end
    end

    def self.github_team_authenticate!(user, id)
      raise Common::Exceptions::Forbidden, detail: "You don't have access to team #{id}" unless user.team_member?(id)
    end
  end
end

# module Flipper
#   class AdminUserConstraint
#     def current_user_rack(request)
#       access_token_jwt = request.cookies[SignIn::Constants::Auth::ACCESS_TOKEN_COOKIE_NAME]
#       user_uuid = access_token_jwt ? sis_user_uuid(access_token_jwt) : ssoe_user_uuid(request)
#       if (user = User.find(user_uuid))
#         # We've set this in a thread because we want to log who has made a change in
#         # Flipper::Instrumentation::EventSubscriber but at that point we don't have access to the request or session
#         # objects at that point and the request goint to a simple rack app.
#         RequestStore.store[:flipper_user_email_for_log] = user&.email
#         user
#       else
#         RequestStore.store[:flipper_user_email_for_log] = nil
#         nil
#       end
#     end

#     def matches?(request)
#       current_user = current_user_rack(request)
#       (current_user && Settings.flipper.admin_user_emails.include?(current_user.email) && current_user.loa3?) ||
#         request.method == 'GET' || Rails.env.development?
#     end

#     private

#     def sis_user_uuid(access_token_jwt)
#       access_token = SignIn::AccessTokenJwtDecoder.new(access_token_jwt:).perform
#       access_token&.user_uuid
#     end

#     def ssoe_user_uuid(request)
#       session_token = request.session[:token]
#       session = Session.find(session_token)
#       session&.uuid
#     end
#   end
# end
