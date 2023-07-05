module Avs
    module V0
        class AvsController < ApplicationController
            # before_action { :authenticate }
            # FIXME: This is a temporary workaround to allow the swagger docs to be generated.
            skip_before_action :authenticate

            def index
                response = { status: 200, message: 'success', data: [ { id: 123, path: '/my-health/medical-records/care-summaries/avs/123' } ]}
                render json: response, status: response[:status]
            end

            def show
                response = { status: 200, message: 'success', data: { id: 123, path: '/my-health/medical-records/care-summaries/avs/123' } }
                render json: response, status: response[:status]
            end

        end
    end
end