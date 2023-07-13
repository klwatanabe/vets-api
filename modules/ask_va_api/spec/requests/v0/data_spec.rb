# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AskVAApi::V0::Data', type: :request do
  describe 'index' do
    let(:user) { build(:user, :loa3) }
    
    before do
      sign_in(user)
      get '/ask_va_api/v0/data'
    end

    it 'response with status :ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
