# frozen_string_literal: true

require 'common/exceptions'
require 'common/client/errors'

module VAOS
  module V2
    class AVSService < Avs::V0::AvsService
      # TODO: might not need any of this

      # def config
      #   VAOS::AVSConfiguration.instance
      # end

      # Retrieve an avs link based on specific station id and ien combination.
      #
      # station_id - facility identifier.
      # ien - appointment identifier.
      #
      # Returns a new OpenStruct object that contains the avs data.
      # def get_avs(station_id, ien)
      #   params = { station_id, ien }
      #   with_monitoring do
      #     response = perform(:get, avs_url, params, headers)
      #     OpenStruct.new(response[:body])
      #   end
      # end

      # private

      # def avs_url
      #   "/avs/v0/avs/search"
      # end
    end
  end
end
