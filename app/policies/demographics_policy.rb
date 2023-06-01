# frozen_string_literal: true

DemographicsPolicy = Struct.new(:user, :gender_identity) do
  def allowed_providers
    %w[
      idme
      oauth_IDME
      logingov
      oauth_LOGINGOV
    ].freeze
  end

  def access?
    user.loa3? &&
      allowed_providers.include?(user.identity.sign_in[:service_name])
  end

  def access_update?
    user.loa3? &&
      allowed_providers.include?(user.identity.sign_in[:service_name])
  end

  def legacy_access?
    user.loa3? &&
      (user&.idme_uuid.present? || user&.logingov_uuid.present?)
  end
end
