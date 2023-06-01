# frozen_string_literal: true

require 'rails_helper'
require 'support/error_details'

RSpec.describe 'personal_information' do
  include SchemaMatchers
  include ErrorDetails

  let(:user) { create(:user, :loa3) }

  before { sign_in(user) }

  shared_context 'when MHV user logs in with idme uuid' do
    before do
      allow(user).to receive(:idme_uuid).and_return('b2fab2b5-6af0-45e1-a9e2-394347af91ef')
      allow_any_instance_of(UserIdentity).to receive(:sign_in).and_return({ service_name: 'mhv', auth_broker: 'MHV' })
    end
  end

  shared_context 'when profile_personal_info_authorization feature flag is enabled' do
    before do
      allow(Flipper).to receive(:enabled?).with(:profile_personal_info_authorization, instance_of(User))
                                          .and_return(true)
    end
  end

  shared_context 'when profile_personal_info_authorization feature flag is disabled' do
    before do
      allow(Flipper).to receive(:enabled?).with(:profile_personal_info_authorization, instance_of(User))
                                          .and_return(false)
    end
  end

  describe 'GET /v0/profile/personal_information' do
    context 'with a 200 response' do
      it 'matches the personal information schema' do
        VCR.use_cassette('mpi/find_candidate/valid') do
          VCR.use_cassette('va_profile/demographics/demographics') do
            get '/v0/profile/personal_information'

            expect(response).to have_http_status(:ok)
            expect(response).to match_response_schema('personal_information_response')
          end
        end
      end
    end

    describe 'when authorized' do
      include_context 'when MHV user logs in with idme uuid'
      include_context 'when profile_personal_info_authorization feature flag is enabled'

      it 'returns a 200 status code' do
        VCR.use_cassette('va_profile/demographics/demographics') do
          get '/v0/profile/personal_information'

          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe 'when unauthorized' do
      include_context 'when MHV user logs in with idme uuid'
      include_context 'when profile_personal_info_authorization feature flag is disabled'

      it 'returns a 403 status code' do
        VCR.use_cassette('va_profile/demographics/demographics') do
          get '/v0/profile/personal_information'
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'when MVI does not return a gender nor birthday', skip_mvi: true do
      let(:mpi_profile) { build(:mpi_profile, { birth_date: nil, gender: nil }) }
      let(:user) { create(:user, :loa3, mpi_profile:) }

      it 'matches the errors schema', :aggregate_failures do
        VCR.use_cassette('mpi/find_candidate/missing_birthday_and_gender') do
          VCR.use_cassette('va_profile/demographics/demographics') do
            get '/v0/profile/personal_information'
            expect(response).to have_http_status(:bad_gateway)
            expect(response).to match_response_schema('errors')
          end
        end
      end

      it 'includes the correct error code' do
        VCR.use_cassette('mpi/find_candidate/missing_birthday_and_gender') do
          VCR.use_cassette('va_profile/demographics/demographics') do
            get '/v0/profile/personal_information'

            expect(error_details_for(response, key: 'code')).to eq 'MVI_BD502'
          end
        end
      end
    end

    context 'when VAProfile does not return a preferred name nor gender identity' do
      it 'matches the errors schema', :aggregate_failures do
        VCR.use_cassette('mpi/find_candidate/valid') do
          VCR.use_cassette('va_profile/demographics/demographics_error_503') do
            get '/v0/profile/personal_information'

            expect(response).to have_http_status(:bad_gateway)
            expect(response).to match_response_schema('errors')
          end
        end
      end
    end
  end
end
