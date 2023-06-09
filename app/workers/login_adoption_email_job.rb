# frozen_string_literal: true

class LoginAdoptionEmailJob
  include Sidekiq::Worker

  sidekiq_options retry: false

  attr_accessor :user

  REACTIVATION_TEMPLATE = Settings.vanotify.services.va_gov.template_id.login_reactivation_email

  def initialize(user)
    @user = user
  end

  def perform
    return unless signed_in_with_legacy_credential?
    return unless Flipper.enabled?(:reactivation_experiment, @user)

    send_email if user_qualifies_for_reactivation?
  end

  def send_email
    email = @user.email

    return if email.blank?

    VANotify::EmailJob.perform_async(
      email,
      REACTIVATION_TEMPLATE,
      {
        # personalization stuff goes here
      }
    )
  end

  private

  def credential_type
    @credential_type ||= @user.identity.sign_in[:service_name]
  end

  def logged_in_with_dsl?
    credential_type == SAML::User::DSLOGON_CSID
  end

  def logged_in_with_mhv?
    credential_type == SAML::User::MHV_ORIGINAL_CSID
  end

  def signed_in_with_legacy_credential?
    logged_in_with_dsl? || logged_in_with_mhv?
  end

  def verified_credential_at?
    user_avc = UserAcceptableVerifiedCredential.find_by(user_account: @user.user_account)
    user_avc&.acceptable_verified_credential_at || user_avc&.idme_verified_credential_at
  end

  def user_qualifies_for_reactivation?
    signed_in_with_legacy_credential? && verified_credential_at?
  end
end
