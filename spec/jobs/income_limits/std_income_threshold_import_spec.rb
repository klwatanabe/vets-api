# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe IncomeLimits::StdIncomeThresholdImport, type: :worker do
  describe '#perform' do
    let(:csv_url) { 'https://sitewide-public-websites-income-limits-data.s3-us-gov-west-1.amazonaws.com/std_incomethreshold.csv' }
    let(:csv_data) do
      <<-CSV
        ID,INCOME_THRESHOLD_YEAR,EXEMPT_AMOUNT,MEDICAL_EXPENSE_DEDUCTIBLE,CHILD_INCOME_EXCLUSION,DEPENDENT,ADD_DEPENDENT_THRESHOLD,PROPERTY_THRESHOLD,PENSION_THRESHOLD,PENSION_1_DEPENDENT,ADD_DEPENDENT_PENSION,NINETY_DAY_HOSPITAL_COPAY,ADD_90_DAY_HOSPITAL_COPAY,OUTPATIENT_BASIC_CARE_COPAY,OUTPATIENT_SPECIALTY_COPAY,THRESHOLD_EFFECTIVE_DATE,AID_AND_ATTENDANCE_THRESHOLD,OUTPATIENT_PREVENTIVE_COPAY,MEDICATION_COPAY,MEDICATIN_COPAY_ANNUAL_CAP,LTC_INPATIENT_COPAY,LTC_OUTPATIENT_COPAY,LTC_DOMICILIARY_COPAY,INPATIENT_PER_DIEM,DESCRIPTION,VERSION,CREATED,UPDATED,CREATED_BY,UPDATED_BY
        1,2023,1000,200,500,2,300,100000,15000,5000,2000,50,25,10,15,01/01/2023,300,5,5,1000,75,100,50,250,Description A,1,01/01/2023,01/02/2023,John,Doe
      CSV
    end

    before do
      allow(URI).to receive(:open).with(csv_url).and_return(StringIO.new(csv_data))
    end

    context 'when a matching record already exists' do
      let!(:existing_threshold) { create(:std_income_threshold, id: 1) }

      it 'does not create a new record' do
        expect do
          described_class.new.perform
        end.not_to change(StdIncomeThreshold, :count)
      end
    end

    context 'when a matching record does not exist' do
      it 'creates a new record' do
        expect do
          described_class.new.perform
        end.to change(StdIncomeThreshold, :count).by(1)
      end

      it 'sets the attributes correctly' do
        described_class.new.perform
        threshold = StdIncomeThreshold.last
        expect(threshold.income_threshold_year).to eq(2023)
        expect(threshold.exempt_amount).to eq(1000)
        expect(threshold.medical_expense_deductible).to eq(200)
        expect(threshold.child_income_exclusion).to eq(500)
        expect(threshold.dependent).to eq(2)
        expect(threshold.add_dependent_threshold).to eq(300)
        expect(threshold.property_threshold).to eq(100_000)
        expect(threshold.pension_threshold).to eq(15_000)
        expect(threshold.pension_1_dependent).to eq(5000)
        expect(threshold.add_dependent_pension).to eq(2000)
        expect(threshold.ninety_day_hospital_copay).to eq(50)
        expect(threshold.add_ninety_day_hospital_copay).to eq(25)
        expect(threshold.outpatient_basic_care_copay).to eq(10)
        expect(threshold.outpatient_specialty_copay).to eq(15)
        expect(threshold.threshold_effective_date).to eq(Date.new(2023, 1, 1))
        expect(threshold.aid_and_attendance_threshold).to eq(300)
        expect(threshold.outpatient_preventive_copay).to eq(5)
        expect(threshold.medication_copay).to eq(5)
        expect(threshold.medication_copay_annual_cap).to eq(1000)
        expect(threshold.ltc_inpatient_copay).to eq(75)
        expect(threshold.ltc_outpatient_copay).to eq(100)
        expect(threshold.ltc_domiciliary_copay).to eq(50)
        expect(threshold.inpatient_per_diem).to eq(250)
        expect(threshold.description).to eq('Description A')
        expect(threshold.version).to eq(1)
        expect(threshold.created).to eq(Date.new(2023, 1, 1))
        expect(threshold.updated).to eq(Date.new(2023, 1, 2))
        expect(threshold.created_by).to eq('John')
        expect(threshold.updated_by).to eq('Doe')
      end
    end
  end
end
