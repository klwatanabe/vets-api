# frozen_string_literal: true

# spec/workers/std_state_import_spec.rb
require 'rails_helper'
require 'csv'

RSpec.describe StdStateImport, type: :worker do
  describe '#perform' do
    let(:csv_data) do
      <<-CSV
        ID,NAME,POSTALNAME,FIPSCODE,COUNTRY_ID,VERSION,CREATED,UPDATED,CREATEDBY,UPDATEDBY
        1,State A,Postal A,123,2,1,01/01/2023,01/02/2023,John,Doe
      CSV
    end

    before do
      allow(CSV).to receive(:parse).and_return(CSV.parse(csv_data, headers: true))
    end

    it 'creates a new StdState record' do
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
