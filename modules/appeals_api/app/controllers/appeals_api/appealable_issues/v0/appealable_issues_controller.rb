# frozen_string_literal: true

require 'appeals_api/form_schemas'

module AppealsApi::AppealableIssues::V0
  class AppealableIssuesController < AppealsApi::V2::DecisionReviews::ContestableIssuesController
    include AppealsApi::OpenidAuth
    include AppealsApi::Schemas

    # This validation happens manually in #index now; remove this once inheritance relationship is gone:
    skip_before_action :validate_json_schema

    SCHEMA_OPTIONS = { schema_version: 'v0', api_name: 'appealable_issues' }.freeze

    OAUTH_SCOPES = {
      GET: %w[veteran/AppealableIssues.read representative/AppealableIssues.read system/AppealableIssues.read],
      # NOTE: the POST scopes for this API are "read" scopes because this API does not actually write any data.
      # These are used in the index action when POSTing PII to list any matching appealable issues:
      POST: %w[veteran/AppealableIssues.read representative/AppealableIssues.read system/AppealableIssues.read]
    }.freeze

    VALID_DECISION_REVIEW_TYPES = %w[higher-level-reviews notice-of-disagreements supplemental-claims].freeze

    def schema
      render json: AppealsApi::JsonSchemaToSwaggerConverter.remove_comments(form_schemas.schema('APPEALABLE_ISSUES'))
    end

    def index
      form_schemas.validate!('APPEALABLE_ISSUES', params.to_unsafe_h)

      get_appealable_issues_from_caseflow

      if caseflow_response_has_a_body_and_a_status?
        render_response(caseflow_response)
      else
        render_unusable_response_error
      end
    end

    private

    def invalid_decision_review_type?
      !params[:decisionReviewType].in?(VALID_DECISION_REVIEW_TYPES)
    end

    def invalid_benefit_type?
      params[:decisionReviewType] != 'notice-of-disagreements' &&
        !params[:benefitType].in?(caseflow_benefit_type_mapping.keys)
    end

    def validate_params
      if invalid_decision_review_type?
        render_unprocessable_entity(
          "decisionReviewType must be one of: #{VALID_DECISION_REVIEW_TYPES.join(', ')}"
        )
      elsif invalid_benefit_type?
        render_unprocessable_entity(
          "benefitType must be one of: #{caseflow_benefit_type_mapping.keys.join(', ')}"
        )
      end
    end

    def token_validation_api_key
      # FIXME: rename token storage key
      Settings.dig(:modules_appeals_api, :token_validation, :contestable_issues, :api_key)
    end

    def get_appealable_issues_from_caseflow(filter: true)
      headers = generate_caseflow_headers
      decision_review_type = if params[:decisionReviewType] == 'notice-of-disagreements'
                               'appeals'
                             else
                               params[:decisionReviewType].to_s.underscore
                             end
      benefit_type = params[:decisionReviewType] == 'notice-of-disagreements' ? '' : params[:benefitType].to_s

      @caseflow_response ||= filtered_caseflow_response(
        decision_review_type,
        Caseflow::Service.new.get_contestable_issues(headers:, decision_review_type:, benefit_type:),
        filter
      )
    rescue Common::Exceptions::BackendServiceException => @backend_service_exception # rubocop:disable Naming/RescuedExceptionsVariableName
      log_caseflow_error 'BackendServiceException',
                         backend_service_exception.original_status,
                         backend_service_exception.original_body

      raise unless caseflow_returned_a_4xx?

      @caseflow_response = caseflow_response_from_backend_service_exception
    end

    def generate_caseflow_headers
      headers = { 'X-VA-Receipt-Date' => params[:receiptDate] }
      headers.merge!({ 'X-VA-SSN' => params[:ssn] }) if params[:ssn].present?
      headers.merge!({ 'X-VA-File-Number' => params[:fileNumber] }) if params[:fileNumber].present?
    end

    def filtered_caseflow_response(decision_review_type, caseflow_response, filter)
      super

      if caseflow_response&.body.is_a? Hash
        caseflow_response.body.fetch('data', []).each do |issue|
          # Responses from caseflow still have the older name 'contestableIssue'
          issue['type'] = 'appealableIssue' if issue['type'] == 'contestableIssue'
        end
      end

      caseflow_response
    end
  end
end
