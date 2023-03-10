module ClaimsApi
  class ClaimsUser
    def initialize(id)
      @id = id
    end

    def set_icn(icn)
      @icn = icn
    end

    attr_reader :icn

    def first_name_last_name(first_name, last_name)
      @first_name = first_name
      @last_name = last_name
    end

    attr_reader :first_name

    attr_reader :last_name
  end
end