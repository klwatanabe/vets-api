# frozen_string_literal: true

module Users
  class Form526UserIdentificationVerifier
    FORM526_REQUIRED_IDENTIFIERS = %w[participant_id birls_id ssn birth_date edipi].freeze

    def initialize(user)
      @user = user
    end

    def missing_identifiers
      FORM526_REQUIRED_IDENTIFIERS.select { |id| @user[id].blank? }
    end
  end
end
