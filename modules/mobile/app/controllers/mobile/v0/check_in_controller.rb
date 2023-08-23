# frozen_string_literal: true

module Mobile
  module V0
    class CheckInController < ApplicationController
      def create
        render json: chip_service.post_patient_check_in(appointment_ien: params[:appointmentIEN], patient_dfn:, station_no: params[:locationId])
      end

      private

      def patient_dfn
        @current_user.vha_facility_hash[params[:locationId]][0]
      end

      def chip_service
        settings = Settings.chip.mobile_app

        chip_creds = {
          tenant_id: settings.tenant_id,
          tenant_name: 'mobile_app',
          username: settings.username,
          password: settings.password,
        }.freeze

        Chip::Service.new(chip_creds)
      end
    end
  end
end
