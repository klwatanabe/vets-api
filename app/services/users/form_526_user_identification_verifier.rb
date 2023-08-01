# frozen_string_literal: true

module Users
  class Form526UserIdentificationVerifier
    FORM526_REQUIRED_IDENTIFIERS = %w[participant_id birls_id ssn birth_date edipi].freeze

    def self.call(*args)
      new(*args).call
    end

    def initialize(user)
      @user = user
    end

    def call
      identifer_mapping
    end

    private

    def identifer_mapping
      FORM526_REQUIRED_IDENTIFIERS.index_with { |identifier| @user[identifier].present? }
    end
  end
end
