# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::Form526UserIdentificationVerifier do
  describe '#missing_identifiers' do
    let(:user) { build(:user) }

    describe 'participant_id validation' do
      context 'when participant_id is missing' do
        it "returns an array with 'participant_id' in it" do
          allow(user).to receive(:participant_id).and_return(nil)
          expect(Users::Form526UserIdentificationVerifier.call(user)).to include('participant_id')
        end
      end

      context 'when participant_id is present' do
        it 'does not return an array with participant_id in it' do
          allow(user).to receive(:participant_id).and_return('8675309')
          expect(Users::Form526UserIdentificationVerifier.call(user)).not_to include('participant_id')
        end
      end
    end

    describe 'birls_id validation' do
      context 'when birls_id is missing' do
        it "returns an array with 'birls_id' in it" do
          allow(user).to receive(:birls_id).and_return(nil)
          expect(Users::Form526UserIdentificationVerifier.call(user)).to include('birls_id')
        end
      end

      context 'when birls_id is present' do
        it 'does not return an array with birls_id in it' do
          allow(user).to receive(:birls_id).and_return('8675309')
          expect(Users::Form526UserIdentificationVerifier.call(user)).not_to include('birls_id')
        end
      end
    end

    describe 'ssn validation' do
      context 'when ssn is missing' do
        it "returns an array with 'ssn' in it" do
          allow(user).to receive(:ssn).and_return(nil)
          expect(Users::Form526UserIdentificationVerifier.call(user)).to include('ssn')
        end
      end

      context 'when ssn is present' do
        it 'does not return an array with ssn in it' do
          allow(user).to receive(:ssn).and_return('8675309')
          expect(Users::Form526UserIdentificationVerifier.call(user)).not_to include('ssn')
        end
      end
    end

    describe 'birth_date validation' do
      context 'when birth_date is missing' do
        it "returns an array with 'birth_date' in it" do
          allow(user).to receive(:birth_date).and_return(nil)
          expect(Users::Form526UserIdentificationVerifier.call(user)).to include('birth_date')
        end
      end

      context 'when birth_date is present' do
        it 'does not return an array with birth_date in it' do
          allow(user).to receive(:birth_date).and_return('1985-10-26')
          expect(Users::Form526UserIdentificationVerifier.call(user)).not_to include('birth_date')
        end
      end
    end

    describe 'edipi validation' do
      context 'when edipi is missing' do
        it "returns an array with 'edipi' in it" do
          allow(user).to receive(:edipi).and_return(nil)
          expect(Users::Form526UserIdentificationVerifier.call(user)).to include('edipi')
        end
      end

      context 'when edipi is present' do
        it 'does not return an array with edipi in it' do
          allow(user).to receive(:edipi).and_return('8675309')
          expect(Users::Form526UserIdentificationVerifier.call(user)).not_to include('edipi')
        end
      end
    end
  end
end
