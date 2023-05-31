# frozen_string_literal: true

require 'debt_management_center/financial_status_report_service'

module Form5655
  class VBASubmissionJob
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(submission_id, user_params)
      submission = Form5655Submission.find(submission_id)
      DebtManagementCenter::FinancialStatusReportService.new(nil).submit_vba_fsr(submission.form, user_params)
    end
  end
end
