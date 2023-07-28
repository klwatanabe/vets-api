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

                search_response, failures = avs_service.get_avs_by_appointment(station_no, appointment_ien)
                # TODO: filter returned IDs by veteran ICN.

                search_response[:data].empty? ? data = [] : data = [ { path: get_avs_path(search_response[:data][0]["sid"]) } ]
                response = { status: 200, message: 'success', data: data }
                render json: response, status: response[:status]
            end

            def avs_service
                @avs_service ||= Avs::V0::AvsService.new(@user)
            end

            def get_avs_path(sid)
                # TODO: define and use constant for base path.
                "/my-health/medical-records/care-summaries/avs/#{sid}"
            end

        end
    end
end
