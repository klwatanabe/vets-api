# frozen_string_literal: true

require 'lighthouse/benefits_reference_data/service'
module V0
  class BenefitsReferenceDataController < ApplicationController
    include ActionController::Serialization

    def get_data

      if params[:path] == 'disabilities'
        render json: filtered_disabilities
      else
        render json: lighthouse_data
      end
    end

    private

    def benefits_reference_data_service
      BenefitsReferenceData::Service.new
    end

    def lighthouse_data
      Rails.cache.fetch("brd_data_#{params[:path]}",  expires_in: 30.minutes) do
        benefits_reference_data_service
          .get_data(path: params[:path], params: request.query_parameters).body
      end
    end
    def filtered_disabilities
      lighthouse_data.select {|k,v| v.include? params[:name]}
    end
  end
end
