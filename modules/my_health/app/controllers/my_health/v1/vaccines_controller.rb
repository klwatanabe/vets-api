# frozen_string_literal: true

module MyHealth
    module V1
      class VaccinesController < SMController
        def index
          resource = client.get_vaccine(17)
        #   raise Common::Exceptions::InternalServerError if resource.blank?
          render json: resource.to_json
        end
      end
    end
  end
  