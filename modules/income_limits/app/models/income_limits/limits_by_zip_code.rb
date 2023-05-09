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
end
