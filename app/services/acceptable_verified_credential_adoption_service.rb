# frozen_string_literal: true

##
# Supports the transition to an Acceptable Verified Credential
#
# @param user
#
class AcceptableVerifiedCredentialAdoptionService
  attr_accessor :user

  STATS_KEY = 'api.user_transition_availability'

  def initialize(user)
    @user = user
  end

  def perform
    if Flipper.enabled?(:organic_conversion_experiment, user) && user_qualifies_for_conversion?
      organic_conversion_campaign
    elsif user_qualifies_for_reactivation?
      reactivation_campaign
    end

    result[:credential_type] = credential_type

    result
  end

  private

  def result
    @result ||= {}
  end

  def credential_type
    @credential_type ||= user.identity.sign_in[:service_name]
  end

  def user_qualifies_for_conversion?
    (logged_in_with_dsl? || logged_in_with_mhv?) && !verified_credential_at?
  end

  def user_qualifies_for_reactivation?
    (logged_in_with_dsl? || logged_in_with_mhv?) && verified_credential_at?
  end

  def organic_conversion_campaign
    # call mailer from here once implemented?
    result[:campaign] = 'organic'
    log_results('organic_campaign')
  end

  def reactivation_campaign
    # call mailer from here once implemented?
    result[:campaign] = 'reactivation'
    log_results('reactivation_campaign')
  end

  def logged_in_with_dsl?
    credential_type == SAML::User::DSLOGON_CSID
  end

  def logged_in_with_mhv?
    credential_type == SAML::User::MHV_ORIGINAL_CSID
  end

  def verified_credential_at?
    user_avc = UserAcceptableVerifiedCredential.find_by(user_account: user.user_account)
    user_avc&.acceptable_verified_credential_at.present? || user_avc&.idme_verified_credential_at.present?
  end

  def log_results(conversion_type)
    StatsD.increment("#{STATS_KEY}.#{conversion_type}.#{credential_type}")
  end
end
