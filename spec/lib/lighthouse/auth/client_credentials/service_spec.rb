# frozen_string_literal: true

require 'rails_helper'
require 'lighthouse/auth/client_credentials/service'

RSpec.describe Auth::ClientCredentials::Service do
  let(:url) { 'https://sandbox-api.va.gov/oauth2/api/system/v1/token' }
  let(:client_id) { '1234567890' }
  let(:api_scopes) { %w[api.read api.write] }
  let(:aud_claim_url) { 'https://deptva-eval.okta.com/oauth2/1234567890/v1/token' }
  let(:key_location) { 'spec/support/certificates/lhdd-fake-private.pem' }
  let(:service_name) { 'test_service' }

  before do
    t = Time.zone.local(2022, 1, 30, 10, 0, 0)
    Timecop.freeze(t)
  end

  describe 'using Redis caching strategy' do
    context 'cache hit' do
      before do
        token = 'cached.access_token'
        allow(Auth::ClientCredentials::AccessTokenTracker).to receive(:get_access_token)
          .and_return(token)
      end

      it 'uses the AccessTokenTracker to get cached access token' do
        service = described_class.new(url, api_scopes, client_id, aud_claim_url, key_location, service_name)
        token = service.get_token

        expect(token).to eq('cached.access_token')
      end
    end

    context 'cache miss' do
      before do
        token = 'fresh.access_token'
        mock_token_response = OpenStruct.new({ body: { 'access_token' => token, 'expires_in' => 300 } })

        allow_any_instance_of(Auth::ClientCredentials::Configuration).to receive(:get_access_token)
          .and_return(mock_token_response)
        allow(Auth::ClientCredentials::AccessTokenTracker).to receive(:get_access_token)
          .and_return(nil)
      end

      it 'retrieves a fresh token when there is a cache miss' do
        service = described_class.new(url, api_scopes, client_id, aud_claim_url, key_location, service_name)
        token = service.get_token

        expect(token).to eq('fresh.access_token')
      end
    end

    # Utilizing the cache is opt-in currently, if consumers don't provide a service_name
    # or they set it to nil, then we want to skip the cache
    context 'skip cache when service_name is not provided or nil' do
      before do
        token = 'fresh.access_token'
        allow_any_instance_of(Auth::ClientCredentials::Configuration).to receive(:get_access_token)
          .and_return(OpenStruct.new({ body: { 'access_token' => token, 'expires_in' => 300 } }))
        allow(Auth::ClientCredentials::AccessTokenTracker).to receive(:get_access_token)
          .and_return('cached.access_token')
      end

      it 'always retrieves a fresh token when service_name is not defined' do
        service = described_class.new(url, api_scopes, client_id, aud_claim_url, key_location)
        token = service.get_token

        expect(token).to eq('fresh.access_token')
      end

      it 'always retrieves a fresh token when service_name is nil' do
        service = described_class.new(url, api_scopes, client_id, aud_claim_url, key_location, nil)
        token = service.get_token

        expect(token).to eq('fresh.access_token')
      end
    end
  end

  describe 'get access_token from Lighthouse API' do
    context 'when successful' do
      it 'returns a status of 200' do
        service = described_class.new(url, api_scopes, client_id, aud_claim_url, key_location)

        VCR.use_cassette('lighthouse/auth/client_credentials/token_200') do
          access_token = service.get_token
          expect(access_token).not_to be_nil
        end
      end
    end

    context 'when invalid client_id provided' do
      it 'returns a 400' do
        service = described_class.new(url, api_scopes, '', aud_claim_url, key_location)

        VCR.use_cassette('lighthouse/auth/client_credentials/invalid_client_id_400') do
          expect { service.get_token }.to raise_error do |error|
            expect(error).to be_a(Faraday::ClientError)
            expect(error.response[:status]).to eq(400)
            expect(error.response[:body]['error']).to eq('invalid_client')
            expect(error.response[:body]['error_description']).to eq('A client_id must be provided in the request.')
          end
        end
      end
    end

    context 'when invalid aud_claim_id provided' do
      it 'returns a 401' do
        error_message = 'The audience claim for client_assertion must be the endpoint invoked for the request.'
        service = described_class.new(url, api_scopes, client_id, '', key_location)

        VCR.use_cassette('lighthouse/auth/client_credentials/invalid_assertion_401') do
          expect { service.get_token }.to raise_error do |error|
            expect(error).to be_a(Faraday::ClientError)
            expect(error.response[:status]).to eq(401)
            expect(error.response[:body]['error']).to eq('invalid_client')
            expect(error.response[:body]['error_description']).to eq(error_message)
          end
        end
      end
    end

    context 'when invalid scopes are provided' do
      it 'returns a 400' do
        fake_scopes = %w[direct.deposit.fake direct.deposit.write]
        error_message = 'One or more scopes are not configured for the authorization server resource.'
        service = described_class.new(url, fake_scopes, client_id, aud_claim_url, key_location)

        VCR.use_cassette('lighthouse/auth/client_credentials/invalid_scopes_400') do
          expect { service.get_token }.to raise_error do |error|
            expect(error).to be_a(Faraday::ClientError)
            expect(error.response[:status]).to eq(400)
            expect(error.response[:body]['error']).to eq('invalid_scope')
            expect(error.response[:body]['error_description']).to eq(error_message)
          end
        end
      end
    end
  end
end
