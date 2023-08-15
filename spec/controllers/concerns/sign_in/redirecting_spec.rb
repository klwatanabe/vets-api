# frozen_string_literal: true

# spec/sign_in/redirecting_spec.rb
require 'rails_helper'

RSpec.describe SignIn::Redirecting, type: :controller do
  let(:redirect_uri) { 'https://www.example.com' }

  controller(ApplicationController) do
    skip_before_action :authenticate
    include SignIn::Redirecting

    def test_meta_redirect_to
      meta_redirect_to params[:redirect_uri]
    end
  end

  before do
    routes.draw { get 'test_meta_redirect_to' => 'anonymous#test_meta_redirect_to' }
  end

  describe '#meta_redirect_to' do
    let(:expected_html) do
      <<-HTML.squish
        <html lang="en">
          <head>
            <meta charset="utf-8">
            <meta http-equiv="refresh" content="0; url=#{redirect_uri}">
            <title>Redirecting</title>
          </head>
        </html>
      HTML
    end

    before do
      allow(controller).to receive(:_compute_redirect_to_location).and_return(redirect_uri)
      get :test_meta_redirect_to, params: { redirect_uri: }
    end

    it 'sets the status to 200' do
      expect(response).to have_http_status(:ok)
    end

    it 'sets the location header' do
      expect(response.headers['Location']).to eq(redirect_uri)
    end

    it 'sets the response body with js_redirect_body' do
      expect(response.body).to eq(expected_html)
      expect(response.location).to eq(redirect_uri)
    end

    it 'raises an error if options are nil' do
      expect do
        controller.meta_redirect_to(nil)
      end.to raise_error(ActionController::ActionControllerError, 'Cannot redirect to nil!')
    end

    it 'raises an error if response body is already set' do
      allow(controller).to receive(:response_body).and_return('something')
      expect { controller.meta_redirect_to redirect_uri }.to raise_error(AbstractController::DoubleRenderError)
    end
  end
end
