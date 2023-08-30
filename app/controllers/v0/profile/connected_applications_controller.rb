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

        icn = app.user.icn
        client_id = :id

        root_url = request.base_url == 'https://api.va.gov' ? 'https://api.va.gov' : 'https://sandbox-api.va.gov'
        revocation_url = "#{root_url}/internal/auth/v3/user/consent"

        payload = { icn:, client_id: }

        begin
          response = RestClient.delete(revocation_url, params: payload)

          if response.code == 204
            head :no_content
          else
            render json: { error: 'Something went wrong cannot revoke grants' }, status: :unprocessable_entity
          end
        end
      end

      private

      def apps_from_grants
        apps = {}
        app.user = @current_user
        icn = app.user.icn

        root_url = request.base_url == 'https://api.va.gov' ? 'https://api.va.gov' : 'https://sandbox-api.va.gov'
        grant_url = "#{root_url}/internal/auth/v3/user/connected-apps"

        payload = { icn: }

        response = RestClient.get(grant_url, params: payload)
        if response.code == 200
          parsed_response = JSON.parse(response)
          apps = parsed_response['apps']
        end
        apps
      end

      def connected_accounts_params
        params.permit(:id)
      end
    end
  end
end
