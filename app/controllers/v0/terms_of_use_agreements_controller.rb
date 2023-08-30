# frozen_string_literal: true

module V0
  class TermsOfUseAgreementsController < ApplicationController
    before_action :set_user_account
    before_action :set_terms_of_use_agreement, only: %i[accept decline]

    STATSD_PREFIX = 'api.terms_of_use_agreements'

    def latest
      @latest_terms_of_use_agreement = @user_account.terms_of_use_agreements
                                                    .where(agreement_version: params[:version])
                                                    .last
      render json: { terms_of_use_agreement: @latest_terms_of_use_agreement }, status: :ok
    end

    def accept
      if @terms_of_use_agreement.accepted!
        render json: { terms_of_use_agreement: @terms_of_use_agreement }, status: :created
        log_success
      else
        render_error
      end
    end

    def decline
      if @terms_of_use_agreement.declined!
        render json: { terms_of_use_agreement: @terms_of_use_agreement }, status: :created
        log_success
      else
        render_error
      end
    end

    private

    def set_user_account
      @user_account = current_user.user_account
    end

    def set_terms_of_use_agreement
      @terms_of_use_agreement = @user_account.terms_of_use_agreements.new(agreement_version: params[:version])
    end

    def log_success
      context = {
        terms_of_use_agreement_id: @terms_of_use_agreement.id,
        user_account_id: @user_account.id,
        icn: @user_account.icn,
        agreement_version: @terms_of_use_agreement.agreement_version,
        response: @terms_of_use_agreement.response
      }

      Rails.logger.info("[TermsOfUseAgreementsController] [#{@terms_of_use_agreement.response}]", context)

      StatsD.increment("#{STATSD_PREFIX}.#{@terms_of_use_agreement.response}",
                       tags: ["agreement_version:#{@terms_of_use_agreement.agreement_version}"])
    end

    def render_error
      render json: { error: @terms_of_use_agreement.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end
end
