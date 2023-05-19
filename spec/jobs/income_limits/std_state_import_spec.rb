# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe IncomeLimits::StdStateImport, type: :worker do
  describe '#perform' do
    let(:csv_url) { 'https://sitewide-public-websites-income-limits-data.s3-us-gov-west-1.amazonaws.com/std_state.csv' }
    let(:csv_data) do
      <<-CSV
        ID,NAME,POSTALNAME,FIPSCODE,COUNTRY_ID,VERSION,CREATED,UPDATED,CREATEDBY,UPDATEDBY
        1,State A,Postal A,123,2,1,01/01/2023,01/02/2023,John,Doe
      CSV
    end

    before do
      allow(URI).to receive(:open).with(csv_url).and_return(StringIO.new(csv_data))
    end

    context 'when a matching record already exists' do
      let!(:existing_state) { create(:std_state, id: 1) }

      it 'does not create a new record' do
        expect do
          described_class.new.perform
        end.not_to change(StdState, :count)
      end
    end

    context 'when a matching record does not exist' do
      it 'creates a new record' do
        expect do
          described_class.new.perform
        end.to change(StdState, :count).by(1)
      end

      it 'sets the attributes correctly' do
        described_class.new.perform
        state = StdState.last
        expect(state.name).to eq('State A')
        expect(state.postal_name).to eq('Postal A')
        expect(state.fips_code).to eq(123)
        expect(state.country_id).to eq(2)
        expect(state.version).to eq(1)
        expect(state.created).to eq(Date.new(2023, 1, 1))
        expect(state.updated).to eq(Date.new(2023, 1, 2))
        expect(state.created_by).to eq('John')
        expect(state.updated_by).to eq('Doe')
      end
    end
  end
end
