# frozen_string_literal: true

module Avs
  module V0
    class AvsController < ApplicationController
      before_action { :authenticate }

      def index
        station_no = params[:stationNo]
        appointment_ien = params[:appointmentIen]
        unless validate_search_param?(station_no) && validate_search_param?(appointment_ien)
          render_client_error('Invalid parameters', 'Station number and Appointment IEN must be present and valid.')
          return
        end

        search_response = avs_service.get_avs_by_appointment(station_no, appointment_ien)
        data = if search_response[:body].empty?
                 {}
               else
                 { path: get_avs_path(search_response[:body][0][:sid]) }
               end

        # rubocop:disable Style/SoleNestedConditional
        unless data.empty?
          unless @current_user.icn == search_response[:body][0][:icn]
            render_client_error('Not authorized', 'User may not view the AVS for this appointment.', :unauthorized)
            return
          end
        end
        # rubocop:enable Style/SoleNestedConditional

        render json: data
      end

      def show
        sid = params[:sid]
        unless validate_sid?(sid)
          render_client_error('Invalid AVS id', 'AVS id does not match accepted format.')
          return
        end

        avs_response = avs_service.get_avs(sid)

        if avs_response[:status] == 404
          render_client_error('Not found', "No AVS found for sid #{sid}", :not_found)
          return
        end

        data = avs_response[:body][:data]
        unless @current_user.icn == data[:patient_info][:icn]
          render_client_error('Not authorized', 'User may not view this AVS.', :unauthorized)
          return
        end

        render json: data
      end

      def avs_service
        @avs_service ||= Avs::V0::AvsService.new(@current_user)
      end

      def get_avs_path(sid)
        # TODO: define and use constant for base path.
        "/my-health/medical-records/care-summaries/avs/#{sid}"
      end

      def render_client_error(title, message, status = :bad_request)
        render json: {
          errors: [
            {
              title:,
              detail: message,
              status:
            }
          ]
        }, status:
      end

      def validate_search_param?(param)
        !param.nil? && /^\d+$/.match(param)
      end

      def validate_sid?(sid)
        /^([A-F0-9]){32}$/.match(sid)
      end
    end
  end
end
