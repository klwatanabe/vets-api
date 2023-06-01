# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/monitored_worker'

module AppealsApi
  class IcnSsnLookupStats
    include Sidekiq::Worker
    include Sidekiq::MonitoredWorker

    # retry up to 10 times over ~4.5 hours
    sidekiq_options retry: 11

    STATSD_KEY = 'api.appeals.icn.lookup.ssn'

    def perform(icn, ssn)
      mpi = MPI::Service.new
      profile = mpi.find_profile_by_identifier(identifier: icn, identifier_type: 'ICN')&.profile

      if profile.nil?
        # could not lookup user by icn
        StatsD.increment STATSD_KEY, tags: ['profile_found:false', 'ssn_matched:na']
      elsif profile&.ssn.blank?
        # found profile, but ssn missing
        StatsD.increment STATSD_KEY, tags: ['profile_found:true', 'ssn_matched:na']
      elsif profile.ssn.strip != ssn.strip
        # found profile, but profile ssn does not match provided ssn
        StatsD.increment STATSD_KEY, tags: ['profile_found:true', 'ssn_matched:false']
      else
        # found profile and ssn matched
        StatsD.increment STATSD_KEY, tags: ['profile_found:true', 'ssn_matched:true']
      end
    end

    def retry_limits_for_notification
      # Notify at last attempt failuer
      [11]
    end

    def notify(retry_params)
      AppealsApi::Slack::Messager.new(retry_params, notification_type: :error_retry).notify!
    end
  end
end

# mpi = MPI::Service.new
# icn = '1012667122V019349'
# profile = mpi.find_profile_by_identifier(identifier: icn, identifier_type: 'ICN')&.profile
# profile.ssn
