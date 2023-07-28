module Avs
    module V0
        class AvsController < ApplicationController
            # before_action { :authenticate }
            # FIXME: This is a temporary workaround to allow testing before launch.
            skip_before_action :authenticate

            def index
                station_no = params[:stationNo]
                appointment_ien = params[:appointmentIen]
                if !validate_search_param?(station_no) || !validate_search_param?(appointment_ien)
                    render json: {
                        errors: [
                            {
                                title: 'Invalid parameters',
                                detail: 'Station number and Appointment IEN must be present and valid.',
                                status: '400'
                            }
                        ]
                        }, status: :bad_request
                    return
                end

                search_response, failures = avs_service.get_avs_by_appointment(station_no, appointment_ien)
                # TODO: filter returned IDs by veteran ICN.

                search_response[:data].empty? ? data = {} : data = { path: get_avs_path(search_response[:data][0]["sid"]) }
                render json: data
            end

            def show
                sid = params[:sid]
                if !validate_sid?(sid)
                    render json: {
                        errors: [
                            {
                                title: 'Invalid AVS id',
                                detail: 'AVS id does not match accepted format.',
                                status: '400'
                            }
                        ]
                        }, status: :bad_request
                    return
                end

                avs_response, failures = avs_service.get_avs(sid)
                # TODO: validate ICN matches logged in veteran.

                if avs_response[:data].nil?
                    render json: {
                        errors: [
                            {
                                title: 'Not found',
                                detail: "No AVS found for sid #{sid}",
                                status: '404'
                            }
                        ]
                        }, status: :not_found
                    return
                end

                avs_response[:data]["sid"] === sid ? data = avs_response[:data] : data = {}
                render json: data
            end

            def avs_service
                @avs_service ||= Avs::V0::AvsService.new(@user)
            end

            def get_avs_path(sid)
                # TODO: define and use constant for base path.
                "/my-health/medical-records/care-summaries/avs/#{sid}"
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
