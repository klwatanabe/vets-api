# frozen_string_literal: true

require 'rails_helper'
require AppealsApi::Engine.root.join('spec', 'spec_helper.rb')

describe AppealsApi::HigherLevelReviews::V0::HigherLevelReviewsController, type: :request do
  describe '#schema' do
    let(:path) { '/services/appeals/higher_level_reviews/v0/schemas/200996' }

    it 'renders the json schema with shared refs' do
      with_openid_auth(%w[claim.read]) do |auth_header|
        get(path, headers: auth_header)
      end

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['description']).to eq('JSON Schema for VA Form 20-0996')
      expect(response.body).to include('{"$ref":"non_blank_string.json"}')
      expect(response.body).to include('{"$ref":"address.json"}')
      expect(response.body).to include('{"$ref":"phone.json"}')
    end

    it_behaves_like('an endpoint with OpenID auth', %w[claim.read]) do
      def make_request(auth_header)
        get(path, headers: auth_header)
      end
    end
  end
end
