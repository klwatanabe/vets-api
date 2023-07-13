# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AskVAApi::V0::DataOff', type: :request do
  describe 'index' do
    before do
      get '/ask_va_api/v0/data_off'
    end

    it 'response with status :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
