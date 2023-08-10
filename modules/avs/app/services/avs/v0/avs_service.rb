# frozen_string_literal: true

require 'common/exceptions'
require 'common/client/errors'
require 'json'

module Avs
  module V0
    class AvsService < Avs::BaseService
      def get_avs_by_appointment(station_no, appointment_ien)
        with_monitoring do
          perform(:get, get_avs_by_appointment_url(station_no, appointment_ien), nil)
        end
      end

      def get_avs_by_appointment_url(station_no, appointment_ien)
        "/avs-by-appointment/#{station_no}/#{appointment_ien}"
      end
    end
  end
end
