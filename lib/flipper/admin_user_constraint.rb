# frozen_string_literal: true

module Flipper
  class AdminUserConstraint
    def self.matches?(request)
      puts '***** matches? ******'
      # require 'pry'; binding.pry;
      # Raise exception for any unauthorized toggles
      # if request.method == 'POST' && request.path.include?('/boolean') 
      url_pattern = %r{\A/flipper/features[^/]+/boolean\z}
      if request.method == 'POST' && request.path.match?(url_pattern)
        require 'pry'; binding.pry;
        return true if authorized?(request.session[:flipper_user])

        raise Common::Exceptions::Forbidden
      end

      # if request.method == 'GET' && request.path.include?('/flipper/features/logout')
      #   puts '****get****'
      #   require 'pry'; binding.pry;
      #   request.session[:flipper_user] = nil
      #   # teardown(request)
      #   request.session.delete('warden.github.oauth')
      #   RequestStore.store[:flipper_user_email_for_log] = nil
      #   RequestStore.store[:flipper_authorized] = false
      #   # require 'pry'; binding.pry;
      #   return false
      # end

      # If Authenticated through GitHub, check authorization to determine what can be shown in views
      if request.session[:flipper_user].present?
        puts '***** present? ******'
        # require 'pry'; binding.pry;
        user = request.session[:flipper_user]
        RequestStore.store[:flipper_user_email_for_log] = user&.email
        RequestStore.store[:flipper_authorized] = authorized?(user)

        return true
      else
        RequestStore.store[:flipper_user_email_for_log] = nil
        RequestStore.store[:flipper_authorized] = false
      end


      # allow GET requests (minus the callback, which needs to pass through to finish auth flow)
      return true if (request.method == 'GET' && request.path.exclude?('/callback')) 
      # return true if (request.method == 'GET' && request.path.exclude?('/callback')) || Rails.env.development?

      authenticate(request)
      puts '****end******'
      require 'pry'; binding.pry;
      true
    end

    def self.authenticate(request)
      RequestStore.store[:flipper_user_email_for_log] = nil
      warden = request.env['warden']
      # require 'pry'; binding.pry;
      warden.authenticate!(scope: :flipper)
    end

    def self.authorized?(user)
      org_name = Settings.flipper.github_organization
      team_id = Settings.flipper.github_team

      user&.organization_member?(org_name) && user&.team_member?(team_id)
    end

    # def self.teardown(request)
    #   warden = request.env['warden']
    #   require 'pry'; binding.pry;
    #   warden.teardown_flow
    # end
  end
end
