# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe IncomeLimits::StdStateImport, type: :worker do
  describe '#perform' do
    let(:csv_data) do
      <<-CSV
ID,NAME,POSTALNAME,FIPSCODE,COUNTRY_ID,VERSION,CREATED,UPDATED,CREATEDBY,UPDATEDBY
1,Maine,Sample County,123,2,1,7/21/2005 12:13:36.000000 PM,7/22/2005 12:13:36.000000 PM,John,Sam
      CSV
    end

    before do
      response = double('response', body: csv_data, code: '200')
      allow_any_instance_of(
        IncomeLimits::StdStateImport
      ).to receive(:fetch_csv_data).and_return(response)
    end

    it 'populates states' do
      IncomeLimits::StdStateImport.new.perform
      expect(StdState.find('Maine')).not_to be_nil
      expect(StdState.find('123')).not_to be_nil
    end

    it 'creates a new StdState record' do
      expect do
        described_class.new.perform
      end.to change(StdState, :count).by(1)
    end

    it 'sets the attributes correctly' do
      described_class.new.perform
      state = StdState.last
      expect(state.name).to eq('Maine')
      expect(state.postal_name).to eq('Postal A')
      expect(state.fips_code).to eq(123)
      expect(state.country_id).to eq(2)
      expect(state.version).to eq(1)
    end
  end
end
