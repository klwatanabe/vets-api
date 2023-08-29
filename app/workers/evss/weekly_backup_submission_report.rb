# frozen_string_literal: true

module EVSS
  class WeeklyErrorReportMailer < ApplicationMailer
    def build(recipients:, body:, start_date:, end_date:)
      mail(
        to: recipients,
        subject: "Weekly 526 Error Report for #{start_date} - #{end_date}",
        content_type: 'text/html',
        body:
      )
    end
  end

  class WeeklyBackupSubmissionReport
    include Sidekiq::Worker

    def perform
      if enabled?
        recipients = Settings.form526_backup.weekly_backup_submission_report.recipients
        WeeklyBackupSubmissionReportJob.new(recipients:).send! if recipients.present?
      end
    end

    private

    def enabled?
      Settings.form526_backup.weekly_backup_submission_report.enabled &&
        Flipper.enabled?(:form526_weekly_error_report_enabled) &&
        FeatureFlipper.send_email?
    end
  end

  class WeeklyBackupSubmissionReportJob
    def initialize(recipients:, start_date: 7.days.ago.beginning_of_week.beginning_of_day,
                   end_date: Time.zone.today.beginning_of_week.beginning_of_day)
      @recipients = recipients
      @start_date = start_date
      @end_date = end_date
    end

    def send!
      Rails.logger.info("Sending Weekly Backup Submission Report for #{@start_date} - #{@end_date}, to #{@recipients}")
      total = Form526Submission.where('created_at BETWEEN ? AND ?', @start_date, @end_date)
      total_count = total.count
      exhausted = total.where(submitted_claim_id: nil).size
      no_ids = total.where(submitted_claim_id: nil).where(backup_submitted_claim_id: nil)
      still_pending = no_ids.reject do |sub|
        sub.form526_job_statuses.any? do |js|
          js.job_class == 'BackupSubmission' && js.status == 'exhausted'
        end
      end.pluck(:id)
      totally_failed_ids = no_ids.pluck(:id) - still_pending
      body = ["#{@start_date} - #{@end_date}"]
      body << %(Total Submissions: #{total_count})
      body << %(Total Number of auto-establish Failures: #{exhausted})
      body << %(Successful Backup Submissions: #{exhausted - no_ids.count})
      body << %(Failed Backup Attempts: #{totally_failed_ids.count})
      body << %(Still Pending/Attempting Submission: #{still_pending.size})
      body << %(Submission IDs Pending: #{still_pending})
      body = body.join('<br>')
      WeeklyErrorReportMailer.build(recipients: @recipients, body:).deliver_now
    end
  end
end
