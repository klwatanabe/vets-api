# frozen_string_literal: true

module AskVAApi
  module V0
    class DataOffController < ApplicationController
      skip_before_action :authenticate
      
      def index
        data = {
          'khoa' => 'khoa.nguyen@oddball.io'
        }
        render json: data, status: :ok
      end
    end
  end
end
