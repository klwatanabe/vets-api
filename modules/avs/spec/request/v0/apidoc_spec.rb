# frozen_string_literal: true

require 'rails_helper'
require 'apivore'

RSpec.describe 'Avs::V0::Apidocs', type: :request do
  include AuthenticatedSessionHelper

  before(:all) do
    get '/avs/v0/apidocs.json'
  end

  context 'json validation' do
    it 'has valid json' do
      get '/avs/v0/apidocs.json'
      json = response.body
      JSON.parse(json).to_yaml
    end
  end

  context 'API Documentation', type: %i[apivore request] do
    subject(:apivore) do
      Apivore::SwaggerChecker.instance_for('/avs/v0/apidocs.json')
    end

    let(:user01) { build(:user, :loa3, { email: 'vets.gov.user+1@gmail.com' }) }

    vcr_options = {
      match_requests_on: %i[path query],
      allow_playback_repeats: true,
      record: :new_episodes
    }

    describe 'avs/v0/avs/search', vcr: vcr_options.merge(cassette_name: '/avs/search') do
      let(:params) do
        {
          '_headers' => {
            'Cookie' => sign_in(user01, nil, true),
            'accept' => 'application/json',
            'content-type' => 'application/json'
          },
          '_query_string' => {
            'appointmentIen' => 'abc',
            'stationNo' => 'cba'
          }.to_query
        }
      end

      it {
        expect(subject).to validate(:get, '/avs/v0/avs/search', 400, params)
      }

      # TODO: test successful search.
    end

    # TODO: test get endpoint.
  end
end
