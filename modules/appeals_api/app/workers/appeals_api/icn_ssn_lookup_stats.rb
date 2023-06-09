# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/monitored_worker'

module AppealsApi
  class IcnSsnLookupStats
    include Sidekiq::Worker
    include Sidekiq::MonitoredWorker

    # retry up to 11 times over ~4.5 hours
    SIDEKIQ_RETRIES = 11
    sidekiq_options retry: SIDEKIQ_RETRIES

    STATSD_KEY = 'api.appeals.icn.lookup.ssn'

    def perform(appeal_id, appeal_class_str)
      # fetch the appeal
      appeal_class = Object.const_get(appeal_class_str)
      appeal = appeal_class.find_by(id: appeal_id)
      return if appeal&.icn.blank?

      mpi = MPI::Service.new
      profile = mpi.find_profile_by_identifier(identifier: appeal.icn, identifier_type: 'ICN')&.profile

      if profile.nil?
        # could not lookup user by icn
        StatsD.increment STATSD_KEY, tags: ['profile_found:false', 'ssn_matched:na']
      elsif profile&.ssn.blank?
        # found profile, but ssn missing
        StatsD.increment STATSD_KEY, tags: ['profile_found:true', 'ssn_matched:na']
      elsif profile.ssn.strip != appeal.ssn.strip
        # found profile, but profile ssn does not match provided ssn
        StatsD.increment STATSD_KEY, tags: ['profile_found:true', 'ssn_matched:false']
      else
        # found profile and ssn matched
        StatsD.increment STATSD_KEY, tags: ['profile_found:true', 'ssn_matched:true']
      end
    end

    def retry_limits_for_notification
      # Notify at last attempt failure
      [SIDEKIQ_RETRIES]
    end

    def notify(retry_params)
      AppealsApi::Slack::Messager.new(retry_params, notification_type: :error_retry).notify!
    end
  end
end
