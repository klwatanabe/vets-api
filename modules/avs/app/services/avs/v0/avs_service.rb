# frozen_string_literal: true

require 'common/exceptions'
require 'common/client/errors'
require 'json'

module Avs
  module V0
    class AvsService < Avs::SessionService
      def get_avs_list(station_no, appointment_ien)

        with_monitoring do
          params = {}
          response = perform(:get, avs_base_url, params, headers)
          {
            data: response.body
          }
        end
      end

      def get_avs(avs_id)
        # TODO: implement this.
      end

      def avs_base_url
        "/avs"
      end

      def get_avs_base_url(avs_id)
        "/avs/#{avs_id}"
      end

    end
  end
end
