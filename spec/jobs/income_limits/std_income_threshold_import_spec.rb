# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe IncomeLimits::StdIncomeThresholdImport, type: :worker do
  describe '#perform' do
    let(:csv_data) do
      <<-CSV
        ID,INCOME_THRESHOLD_YEAR,EXEMPT_AMOUNT,MEDICAL_EXPENSE_DEDUCTIBLE,CHILD_INCOME_EXCLUSION,DEPENDENT,ADD_DEPENDENT_THRESHOLD,PROPERTY_THRESHOLD,PENSION_THRESHOLD,PENSION_1_DEPENDENT,ADD_DEPENDENT_PENSION,NINETY_DAY_HOSPITAL_COPAY,ADD_90_DAY_HOSPITAL_COPAY,OUTPATIENT_BASIC_CARE_COPAY,OUTPATIENT_SPECIALTY_COPAY,THRESHOLD_EFFECTIVE_DATE,AID_AND_ATTENDANCE_THRESHOLD,OUTPATIENT_PREVENTIVE_COPAY,MEDICATION_COPAY,MEDICATIN_COPAY_ANNUAL_CAP,LTC_INPATIENT_COPAY,LTC_OUTPATIENT_COPAY,LTC_DOMICILIARY_COPAY,INPATIENT_PER_DIEM,DESCRIPTION,VERSION,CREATED,UPDATED,CREATED_BY,UPDATED_BY
        1,2023,1000,200,500,2,300,100000,15000,5000,2000,50,25,10,15,01/01/2023,300,5,5,1000,75,100,50,250,Description A,1,01/01/2023,01/02/2023,John,Doe
      CSV
    end

    before do
      allow(CSV).to receive(:parse).and_return(CSV.parse(csv_data, headers: true))
    end

    it 'creates a new StdIncomeThreshold record' do
      expect do
        described_class.new.perform
      end.to change(StdIncomeThreshold, :count).by(1)
    end

    it 'sets the attributes correctly' do
      described_class.new.perform
      threshold = StdIncomeThreshold.last
      expect(threshold.income_threshold_year).to eq(2022)
      expect(threshold.pension_threshold).to eq(1000)
      expect(threshold.pension_1_dependent).to eq(500)
      expect(threshold.add_dependent_pension).to eq(200)
    end
  end
end
