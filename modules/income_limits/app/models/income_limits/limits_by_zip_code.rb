# frozen_string_literal: true

module IncomeLimits

  class StdCounty < ApplicationRecord
    belongs_to :std_state
    validates :id, presence: true, uniqueness: true
    validates :name, presence: true
    validates :county_number, presence: true
    validates :description, presence: true
    validates :state_id, presence: true
    validates :version, presence: true
    validates :created, presence: true
  end

  class GmtThreshold < ApplicationRecord
    validates :id, presence: true, uniqueness: true
    validates :effective_year, presence: true
    validates :state_name, presence: true
    validates :county_name, presence: true
    validates :fips, presence: true
    validates :trhd1, presence: true
    validates :trhd2, presence: true
    validates :trhd3, presence: true
    validates :trhd4, presence: true
    validates :trhd5, presence: true
    validates :trhd6, presence: true
    validates :trhd7, presence: true
    validates :trhd8, presence: true
    validates :msa, presence: true
    validates :version, presence: true
    validates :created, presence: true
  end

  class StdIncomeThreshold < ApplicationRecord
    validates :id, presence: true, uniqueness: true
    validates :income_threshold_year, presence: true
    validates :exempt_amount, presence: true
    validates :medical_expense_deductible, presence: true
    validates :child_income_exclusion, presence: true
    validates :dependent, presence: true
    validates :add_dependent_threshold, presence: true
    validates :property_threshold, presence: true
    validates :version, presence: true
    validates :created, presence: true
  end

  class StdState < ApplicationRecord
    validates :id, presence: true, uniqueness: true
    validates :name, presence: true
    validates :postal_name, presence: true
    validates :fips_code, presence: true
    validates :country_id, presence: true
    validates :version, presence: true
    validates :created, presence: true
    validates :updated, presence: true
  end

  class StdZipcode < ApplicationRecord
    validates :id, presence: true, uniqueness: true
    validates :zipcode, presence: true
    validates :state_id, presence: true
    validates :county_number, presence: true
    validates :version, presence: true
    validates :created, presence: true
    validates :updated, presence: true
  end
end
