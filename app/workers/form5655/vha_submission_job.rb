# frozen_string_literal: true

require 'debt_management_center/financial_status_report_service'

module Form5655
  class VHASubmissionJob
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(submission_id, user_params)
      submission = Form5655Submission.find(submission_id)
      user = User.find(user_params['uuid'])
      DebtManagementCenter::FinancialStatusReportService.new(user).submit_vha_fsr(submission, user_params)
    end
  end
end
