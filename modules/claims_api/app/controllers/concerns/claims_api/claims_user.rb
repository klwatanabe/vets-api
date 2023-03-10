module ClaimsApi
  class ClaimsUser
    def initialize(id, icn)
      @id = id
      @icn = icn
    end

    def initialize(id, first_name, last_name)
      @id = id
      @first_name = first_name
      @last_name = last_name
    end
  end
end