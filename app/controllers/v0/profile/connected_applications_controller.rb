# frozen_string_literal: true
require 'rest-client'

module V0
  module Profile
    class ConnectedApplicationsController < ApplicationController
      def index
        render json: apps_from_grants, each_serializer: OktaAppSerializer
      end

      def destroy
        app = OktaRedis::App.with_id(connected_accounts_params[:id])
        app.user = @current_user

        icn = app.user
        clientId = app.clientId

        root_url = request.base_url == 'https://api.va.gov' ? 'https://api.va.gov' : 'https://sandbox-api.va.gov'
        revocation_url = "#{root_url}/internal/auth/v3/user/consent"

        payload = { icn: icn, clientId: clientId}

        begin
          response = RestClient.delete(revocation_url, params: payload)

          if response.code == 204
            head :no_content
          else
            render json: { error: 'Something went wrong cannot revoke grants'}, status: :unprocessable_entity
          end
      end

      private

      def apps_from_grants
        apps = {}
        @current_user.okta_grants.all.each do |grant|
          links = grant['_links']
          app_id = links['app']['href'].split('/').last
          unless apps[app_id]
            app = OktaRedis::App.with_id(app_id)
            app.user = @current_user
            app.fetch_grants
            apps[app_id] = app
          end
        end
        apps.values
      end

      def connected_accounts_params
        params.permit(:id)
      end
    end
  end
end
