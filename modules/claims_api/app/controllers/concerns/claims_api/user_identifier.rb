module ClaimsApi
  class UserIdentifier
    def initialize(id)
      @id = id
      @loa = {:current => 3, :highest => 3}
    end

    def set_icn(icn)
      @icn = icn
    end

    attr_reader :icn
    attr_reader :loa

    def first_name_last_name(first_name, last_name)
      @first_name = first_name
      @last_name = last_name
    end

    attr_reader :first_name

    attr_reader :last_name
  end
end