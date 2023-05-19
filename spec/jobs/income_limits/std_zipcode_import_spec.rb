# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe IncomeLimits::StdZipcodeImport, type: :worker do
  describe '#perform' do
    let(:csv_url) { 'https://sitewide-public-websites-income-limits-data.s3-us-gov-west-1.amazonaws.com/std_zipcode.csv' }
    let(:csv_data) do
      <<-CSV
        ID,ZIPCODE,ZIPCLASSIFICATION_ID,PREFERREDZIPPLACE_ID,STATE_ID,COUNTYNUMBER,VERSION,CREATED,UPDATED,CREATEDBY,UPDATEDBY
        1,12345,2,3,4,5,1,01/01/2023,01/02/2023,John,Doe
      CSV
    end

    before do
      allow(URI).to receive(:open).with(csv_url).and_return(StringIO.new(csv_data))
    end

    context 'when a matching record already exists' do
      let!(:existing_zipcode) { create(:std_zipcode, id: 1) }

      it 'does not create a new record' do
        expect do
          described_class.new.perform
        end.not_to change(StdZipcode, :count)
      end
    end

    context 'when a matching record does not exist' do
      it 'creates a new record' do
        expect do
          described_class.new.perform
        end.to change(StdZipcode, :count).by(1)
      end

      it 'sets the attributes correctly' do
        described_class.new.perform
        zipcode = StdZipcode.last
        expect(zipcode.zip_code).to eq(12_345)
        expect(zipcode.zip_classification_id).to eq(2)
        expect(zipcode.preferred_zip_place_id).to eq(3)
        expect(zipcode.state_id).to eq(4)
        expect(zipcode.county_number).to eq(5)
        expect(zipcode.version).to eq(1)
        expect(zipcode.created).to eq(Date.new(2023, 1, 1))
        expect(zipcode.updated).to eq(Date.new(2023, 1, 2))
        expect(zipcode.created_by).to eq('John')
        expect(zipcode.updated_by).to eq('Doe')
      end
    end
  end
end
