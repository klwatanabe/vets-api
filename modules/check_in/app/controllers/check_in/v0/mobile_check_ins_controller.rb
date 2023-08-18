# frozen_string_literal: true
require 'chip/service'
require 'json'

module CheckIn
  module V0
    class MobileCheckInsController < CheckIn::ApplicationController
      def create
        response = service.post_patient_check_in(permitted_params[:appointment_ien], permitted_params[:patient_dfn], permitted_params[:station_no])

        render json: response.body
      end

      def permitted_params
        params.permit(:patient_dfn, :station_no, :appointment_ien)
      end

      private

      def service
        @service ||= Chip::Service.new({:tenant_name => 'mobile_app', :tenant_id => '6f1c8b41-9c77-469d-852d-269c51a7d380', :username => 'vetsapiTempUser', :password => 'TzY6DFrnjPE8dwxUMbFf9HjbFqRim2MgXpMpMciXJFVohyURUJAc7W99rpFzhfh2B3sVnn4'})
      end

    end
  end
end


