# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V0::Avs', type: :request do
  before do
    sign_in_as(current_user)
    allow_any_instance_of(Avs::UserService).to receive(:session).and_return('stubbed_token')
  end

  describe 'GET `index`' do
    let(:current_user) { build(:user, :loa3, icn: '64762895576664260') }

    it 'returns error when stationNo is not given' do
      get '/avs/v0/avs/search?stationNo=&appointmentIen=123456'
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns error when appointmentIen is not given' do
      get '/avs/v0/avs/search?stationNo=500&appointmentIen='
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns error when stationNo does not have the correct format' do
      get '/avs/v0/avs/search?stationNo=a5c&appointmentIen=123456'
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns error when appointmentIen does not have the correct format' do
      get '/avs/v0/avs/search?stationNo=500&appointmentIen=123abc'
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns empty response found when AVS not found for appointment' do
      VCR.use_cassette('avs/search/empty') do
        get '/avs/v0/avs/search?stationNo=500&appointmentIen=10000'
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
