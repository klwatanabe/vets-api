# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V0::LettersGeneratorController, type: :controller do
  let(:user) { build(:user, :loa3, icn: '123498767V234859') }
  let(:user_error) { build(:user, :loa3, icn: '1012667145V762142') }

  before do
    token = 'abcdefghijklmnop'

    allow_any_instance_of(Lighthouse::LettersGenerator::Configuration).to receive(:get_access_token).and_return(token)
  end

  describe '#index' do
    before { sign_in_as(user) }

    it 'lists letters available to the user' do
      VCR.use_cassette('lighthouse/letters_generator/index') do
        get(:index)

        expected_important_key = 'letters'
        expect(response.body).to include(expected_important_key)
      end
    end

    context "there is an error" do
      it 'handles a timeout error as a 504' do
        VCR.use_cassette('lighthouse/letters_generator/504_response') do
          get(:index)
        end

        expect(response).to  have_http_status(:gateway_timeout)
      end
    end
  end

  describe '#download' do
    context 'without options' do
      before { sign_in_as(user) }

      it 'returns a pdf' do
        VCR.use_cassette('lighthouse/letters_generator/download') do
          post :download, params: { id: 'BENEFIT_SUMMARY' }

          expect(response.header['Content-Type']).to include('application/pdf')
        end
      end
    end

    context 'with options' do
      before { sign_in_as(user) }

      let(:options) do
        {
          id: 'BENEFIT_SUMMARY',
          'military_service' => true,
          'service_connected_disabilities' => true,
          'service_connected_evaluation' => false,
          'non_service_connected_pension' => false,
          'monthly_award' => false,
          'unemployable' => false,
          'special_monthly_compensation' => false,
          'adapted_housing' => false,
          'chapter35_eligibility' => false,
          'death_result_of_disability' => false,
          'survivors_award' => false
        }
      end

      it 'returns a pdf' do
        VCR.use_cassette('lighthouse/letters_generator/download_with_options') do
          post :download, params: options
          expect(response.header['Content-Type']).to eq('application/pdf')
        end
      end
    end

    context 'when an error occurs' do
      before { sign_in_as(user_error) }

      it 'raises Lighthouse::LettersGenerator::ServiceError' do
        VCR.use_cassette('lighthouse/letters_generator/download_error') do
          post :download, params: { id: 'BENEFIT_SUMMARY' }
        end

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe '#beneficiary' do
    context 'without error' do
      before { sign_in_as(user) }

      it 'returns beneficiary data' do
        VCR.use_cassette('lighthouse/letters_generator/beneficiary') do
          get(:beneficiary)

          beneficiary_response = JSON.parse(response.body)
          expected_important_key = 'benefitInformation'
          expect(beneficiary_response).to include(expected_important_key)
        end
      end
    end
  end
end
