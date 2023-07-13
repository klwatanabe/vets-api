# frozen_string_literal: true

module AskVAApi
  module V0
    class DataController < ApplicationController
      def index
        data = {
          'khoa' => 'khoa.nguyen@oddball.io'
        }
        render json: data, status: :ok
      end
    end
  end
end
