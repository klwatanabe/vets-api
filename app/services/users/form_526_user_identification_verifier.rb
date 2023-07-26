# frozen_string_literal: true

module Users
  class Form526UserIdentificationVerifier
    def initialize(user)
      @user = user
    end

    def missing_identifiers
      missing_ids = []
      missing_ids << 'participant_id' if @user.participant_id.blank?
      missing_ids << 'birls_id' if @user.birls_id.blank?
      missing_ids << 'ssn' if @user.ssn.blank?
      missing_ids << 'birth_date' if @user.birth_date.blank?
      missing_ids << 'edipi' if @user.edipi.blank?

      missing_ids
    end
  end
end
