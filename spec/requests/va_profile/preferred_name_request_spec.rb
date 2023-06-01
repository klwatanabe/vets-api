# frozen_string_literal: true

require 'rails_helper'
require 'va_profile/models/preferred_name'

RSpec.describe 'preferred_name' do
  include SchemaMatchers

  let(:user) { create(:user, :loa3) }
  let(:headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }
  let(:preferred_name) { VAProfile::Models::PreferredName.new(text: 'Pat') }

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

  describe 'PUT /v0/profile/preferred_names' do
    context 'with a 200 response' do
      it 'matches the preferred_name schema', :aggregate_failures do
        VCR.use_cassette('va_profile/demographics/post_preferred_name_success') do
          put('/v0/profile/preferred_names', params: preferred_name.to_json, headers:)

          expect(response).to have_http_status(:ok)
          expect(response).to match_response_schema('va_profile/preferred_name_response')
        end
      end

      it 'returns the correct values', :aggregate_failures do
        VCR.use_cassette('va_profile/demographics/post_preferred_name_success') do
          put('/v0/profile/preferred_names', params: preferred_name.to_json, headers:)

          json = json_body_for(response)['attributes']['preferred_name']
          expect(response).to have_http_status(:ok)
          expect(json['text']).to eq(preferred_name.text)
          expect(json['source_system_user']).to eq('123498767V234859')
        end
      end
    end

    context 'matches the errors schema' do
      it 'when text is blank', :aggregate_failures do
        preferred_name = VAProfile::Models::PreferredName.new(text: nil)

        put('/v0/profile/preferred_names', params: preferred_name.to_json, headers:)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to match_response_schema('errors')
        expect(errors_for(response)).to include "text - can't be blank"
      end

      it 'when text is too long', :aggregate_failures do
        preferred_name = VAProfile::Models::PreferredName.new(text: 'A' * 26)

        put('/v0/profile/preferred_names', params: preferred_name.to_json, headers:)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to match_response_schema('errors')
        expect(errors_for(response)).to include 'text - is too long (maximum is 25 characters)'
      end
    end

    describe 'when MHV user logs in with idme uuid with feature flag enabled' do
      include_context 'when MHV user logs in with idme uuid'
      include_context 'when profile_personal_info_authorization feature flag is enabled'

      it 'returns a 200 status code' do
        VCR.use_cassette('va_profile/demographics/post_preferred_name_success') do
          put('/v0/profile/preferred_names', params: preferred_name.to_json, headers:)

          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe 'when MHV user logs in with idme uuid with feature flag disabled' do
      include_context 'when MHV user logs in with idme uuid'
      include_context 'when profile_personal_info_authorization feature flag is disabled'

      it 'returns a 403 status code' do
        VCR.use_cassette('va_profile/demographics/post_preferred_name_success') do
          put('/v0/profile/preferred_names', params: preferred_name.to_json, headers:)

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
