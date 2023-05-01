class CreateIncomeLimitsTables < ActiveRecord::Migration[6.1]
  create_table :std_counties do |t|
    t.string :name, null: false
    t.integer :countynumber, null: false
    t.string :description, null: false
    t.integer :state_id, null: false
    t.integer :version, null: false
    t.datetime :created, null: false
    t.datetime :updated
    t.string :createdby
    t.string :updatedby
  end
  create_table :gmt_thresholds do |t|
    t.integer :effectiveyear, null: false
    t.string :statename, null: false
    t.string :countyname, null: false
    t.integer :fips, null: false
    t.integer :trhd1, null: false
    t.integer :trhd2, null: false
    t.integer :trhd3, null: false
    t.integer :trhd4, null: false
    t.integer :trhd5, null: false
    t.integer :trhd6, null: false
    t.integer :trhd7, null: false
    t.integer :trhd8, null: false
    t.integer :msa, null: false
    t.string :msaname
    t.integer :version, null: false
    t.datetime :created, null: false
    t.datetime :updated
    t.string :createdby
    t.string :updatedby
  end
  create_table :std_incomethresholds do |t|
    t.integer :income_threshold_year, null: false
    t.integer :exempt_amount, null: false
    t.integer :medical_expense_deductible, null: false
    t.integer :child_income_exclusion, null: false
    t.integer :dependent, null: false
    t.integer :add_dependent_threshold, null: false
    t.integer :property_threshold, null: false
    t.integer :pension_threshold
    t.integer :pension_1_dependent
    t.integer :add_dependent_pension
    t.integer :ninety_day_hospital_copay
    t.integer :add_90_day_hospital_copay
    t.integer :outpatient_basic_care_copay
    t.integer :outpatient_specialty_copay
    t.datetime :threshold_effective_date
    t.integer :aid_and_attendance_threshold
    t.integer :outpatient_preventive_copay
    t.integer :medication_copay
    t.integer :medication_copay_annual_cap
    t.integer :ltc_inpatient_copay
    t.integer :ltc_outpatient_copay
    t.integer :ltc_domiciliary_copay
    t.integer :inpatient_per_diem
    t.string :description
    t.integer :version, null: false
    t.datetime :created, null: false
    t.datetime :updated
    t.string :createdby
    t.string :updatedby
  end
  create_table :std_states do |t|
    t.string :name, null: false
    t.string :postalname, null: false
    t.integer :fipscode, null: false
    t.integer :country_id, null: false
    t.integer :version, null: false
    t.datetime :created, null: false
    t.datetime :updated
    t.string :createdby
    t.string :updatedby
  end
  create_table :std_zipcodes do |t|
    t.integer :zipcode, null: false
    t.integer :zipclassification_id
    t.integer :preferredzipplace_id
    t.integer :state_id, null: false
    t.integer :countynumber, null: false
    t.integer :version, null: false
    t.datetime :created, null: false
    t.datetime :updated
    t.string :createdby
    t.string :updatedby
end
