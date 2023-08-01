# frozen_string_literal: true

require 'rails_helper'
require AppealsApi::Engine.root.join('spec', 'spec_helper.rb')

describe AppealsApi::AppealableIssues::V0::AppealableIssuesController, type: :request do
  describe '#schema' do
    let(:path) { '/services/appeals/appealable-issues/v0/schemas/appealable-issues' }

    it 'renders the json schema for request body with shared refs' do
      with_openid_auth(described_class::OAUTH_SCOPES[:GET]) do |auth_header|
        get(path, headers: auth_header)
      end

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['description']).to eq('JSON Schema for Appealable Issues endpoint')
      expect(response.body).to include('{"$ref":"nonBlankString.json"}')
    end

    it_behaves_like('an endpoint with OpenID auth', scopes: described_class::OAUTH_SCOPES[:GET]) do
      def make_request(auth_header)
        get(path, headers: auth_header)
      end
    end
  end

  describe '#index' do
    let(:headers) { {} }
    let(:ssn) { '872958715' }
    let(:receipt_date) { '2019-12-01' }
    let(:icn) { '1234567890V012345' }
    let(:file_number) { nil }
    let(:decision_review_type) { 'notice-of-disagreements' }
    let(:benefit_type) { 'compensation' }
    let(:params) do
      p = {}
      p['receiptDate'] = receipt_date if receipt_date.present?
      p['ssn'] = ssn if ssn.present?
      p['icn'] = icn if icn.present?
      p['fileNumber'] = file_number if file_number.present?
      p['benefitType'] = benefit_type if benefit_type.present?
      p
    end
    let(:json) { JSON.parse(response.body) }
    let(:default_cassette) { "caseflow/#{decision_review_type.underscore}/contestable_issues" }
    let(:cassette) { default_cassette }
    let(:path) { "/services/appeals/appealable-issues/v0/appealable-issues/#{decision_review_type}" }

    before do
      VCR.use_cassette(cassette) do
        with_openid_auth(described_class::OAUTH_SCOPES[:POST]) do |auth_header|
          post(path, headers: auth_header, params:)
        end
      end
    end

    context 'when all required fields provided' do
      context 'with ssn and not file number' do
        it 'fetches contestable_issues from Caseflow successfully' do
          expect(response).to have_http_status(:ok)
          expect(json['data']).not_to be_nil
        end

        it 'replaces the type "contestableIssue" with "appealableIssue" in responses' do
          json['data'].each { |issue| expect(issue['type']).to eq('appealableIssue') }
        end
      end

      context 'with file number and not ssn' do
        let(:ssn) { nil }
        let(:cassette) { "#{default_cassette}-by-file-number" }
        let(:file_number) { '123456789' }

        it 'fetches contestable_issues from Caseflow successfully' do
          expect(response).to have_http_status(:ok)
          expect(json['data']).not_to be_nil
        end
      end
    end

    context 'when neither ssn nor file number is provided' do
      let(:file_number) { nil }
      let(:ssn) { nil }

      it 'returns two 422 errors with details' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors'].count).to eq(2)
        expect(json['errors'].first['meta']['missing_fields']).to include('ssn')
        expect(json['errors'].last['meta']['missing_fields']).to include('fileNumber')
      end
    end

    context 'when icn not provided' do
      let(:icn) { nil }

      it 'returns a 422 error with details' do
        expect(response).to have_http_status(:unprocessable_entity)
        error = json['errors'][0]
        expect(error['detail']).to include('One or more expected fields were not found')
        expect(error['meta']['missing_fields']).to include('icn')
      end
    end

    context 'when icn does not meet length requirements' do
      let(:icn) { '229384' }

      it 'returns a 422 error with details' do
        expect(response).to have_http_status(:unprocessable_entity)
        error = json['errors'][0]
        expect(error['title']).to eql('Invalid length')
        expect(error['detail']).to include("'#{icn}' did not fit within the defined length limits")
      end
    end

    context 'when icn does not meet pattern requirements' do
      let(:icn) { '22938439103910392' }

      it 'returns a 422 error with details' do
        expect(response).to have_http_status(:unprocessable_entity)
        error = json['errors'][0]
        expect(error['title']).to eql('Invalid pattern')
        expect(error['detail']).to include("'#{icn}' did not match the defined pattern")
      end
    end

    context 'with decision_review_type = HLR' do
      let(:decision_review_type) { 'higher-level-reviews' }
      let(:benefit_type) { 'compensation' }

      it 'GETs contestable_issues from caseflow successfully' do
        expect(response).to have_http_status(:ok)
        expect(json['data']).to be_an Array
      end

      context 'when benefitType is missing' do
        let(:benefit_type) { nil }

        it 'returns a 422 error with details' do
          expect(response).to have_http_status(:unprocessable_entity)
          error = json['errors'][0]
          expect(error['title']).to eql('Unprocessable Entity')
          expect(error['detail']).to include('benefitType must be one of:')
        end
      end
    end

    context 'with decision_review_type = SC' do
      let(:decision_review_type) { 'supplemental-claims' }

      context 'when benefitType is missing' do
        let(:benefit_type) { nil }

        it 'returns a 422 error with details' do
          expect(response).to have_http_status(:unprocessable_entity)
          error = json['errors'][0]
          expect(error['title']).to eql('Unprocessable Entity')
          expect(error['detail']).to include('benefitType must be one of:')
        end
      end
    end
  end
end
