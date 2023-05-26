# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/monitored_worker'

module AppealsApi
  class IcnSsnLookupStats
    def perform(icn)
      mpi = MPI::Service.new
      mpi.find_profile_by_identifier(identifier: icn, identifier_type: 'ICN')
    end
  end
end