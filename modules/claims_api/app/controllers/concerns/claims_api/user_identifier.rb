# frozen_string_literal: true

module ClaimsApi
  class UserIdentifier
    def initialize(id)
      @id = id
      @loa = { current: 3, highest: 3 }
    end

    def set_icn(icn)
      @icn = icn
    end

    attr_reader :icn, :loa, :first_name, :last_name

    def first_name_last_name(first_name, last_name)
      @first_name = first_name
      @last_name = last_name
    end
  end
end
