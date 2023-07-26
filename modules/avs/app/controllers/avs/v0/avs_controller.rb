module Avs
    module V0
        class AvsController < ApplicationController
            # before_action { :authenticate }
            # FIXME: This is a temporary workaround to allow testing before launch.
            skip_before_action :authenticate

            def index
                station_no = params[:stationNo]
                appointment_ien = params[:appointmentIen]
                # TODO: validate stationNo and appointmentIen format.
                if station_no.nil? || appointment_ien.nil?
                    response = { status: 400, message: 'Bad Request', data: [] }
                    render json: response, status: response[:status]
                    return
                end

                avs_list, failures = avs_service.get_avs_list(station_no, appointment_ien)

                # TODO: sort AVS items by date so we can get the most recent.

                Rails.logger.debug(avs_list[:data][0]["id"])

                if avs_list[:data][0]["id"].nil?
                    response = { status: 404, message: 'Not Found', data: [] }
                    render json: response, status: response[:status]
                end

                response = { status: 200, message: 'success', data: [ { path: get_avs_path(avs_list[:data][0]["id"]) } ]}
                render json: response, status: response[:status]
            end

            def avs_service
                @avs_service ||= Avs::V0::AvsService.new(@user)
            end

            def get_avs_path(avs_id)
                # TODO: define constant for base path.
                "/my-health/medical-records/care-summaries/avs/#{avs_id}"
            end

        end
    end
end
