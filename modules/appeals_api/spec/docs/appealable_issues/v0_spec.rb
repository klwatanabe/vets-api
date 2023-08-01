# frozen_string_literal: true

require 'swagger_helper'
require Rails.root.join('spec', 'rswag_override.rb').to_s

require 'rails_helper'
require AppealsApi::Engine.root.join('spec', 'spec_helper.rb')
require AppealsApi::Engine.root.join('spec', 'support', 'doc_helpers.rb')

def swagger_doc
  "modules/appeals_api/app/swagger/appealable_issues/v0/swagger#{DocHelpers.doc_suffix}.json"
end

# rubocop:disable RSpec/VariableName, Layout/LineLength
RSpec.describe 'Appealable Issues', swagger_doc:, type: :request do
  include DocHelpers
  let(:Authorization) { 'Bearer TEST_TOKEN' }

  path '/appealable-issues/{decisionReviewType}' do
    post 'Returns all appealable issues for a specific veteran.' do
      scopes = AppealsApi::AppealableIssues::V0::AppealableIssuesController::OAUTH_SCOPES[:POST]
      tags 'Appealable Issues'
      operationId 'listAppealableIssues'
      description 'Returns all issues associated with a Veteran that have been decided ' \
                  'as of the `receiptDate`. Not all issues returned are guaranteed to be eligible for appeal.'
      security DocHelpers.oauth_security_config(scopes)
      consumes 'application/json'
      produces 'application/json'

      parameter name: :decisionReviewType,
                in: :path,
                required: true,
                description: 'Scoping of appeal type for associated issues',
                schema: {
                  type: 'string',
                  enum: %w[higher-level-reviews notice-of-disagreements supplemental-claims]
                },
                example: 'higher-level-reviews'

      parameter name: :benefitType,
                in: :query,
                description: 'Required if decision review type is Higher Level Review or Supplemental Claims.',
                schema: {
                  type: 'string',
                  enum: %w[
                    compensation
                    pensionSurvivorsBenefits
                    fiduciary
                    lifeInsurance
                    veteransHealthAdministration
                    veteranReadinessAndEmployment
                    loanGuaranty
                    education
                    nationalCemeteryAdministration
                  ]
                },
                example: 'compensation'

      parameter name: :body, in: :body, schema: { '$ref' => '#/components/schemas/listAppealableIssues' }

      let(:decisionReviewType) { 'higher-level-reviews' }
      let(:benefitType) { 'compensation' }
      let(:ssn) { '872958715' }
      let(:receiptDate) { '2019-12-01' }
      let(:icn) { '1234567890V123456' }
      let(:body) { { ssn:, receiptDate:, icn: } }

      response '200', 'JSON:API response returning all appealable issues for a specific veteran.' do
        schema '$ref' => '#/components/schemas/appealableIssues'

        let(:benefitType) { nil }
        let(:decisionReviewType) { 'notice-of-disagreements' }

        it_behaves_like 'rswag example',
                        cassette: 'caseflow/notice_of_disagreements/contestable_issues',
                        desc: 'returns a 200 response',
                        scopes:
      end

      response '404', 'Veteran not found' do
        schema '$ref' => '#/components/schemas/errorModel'

        it_behaves_like 'rswag example',
                        cassette: 'caseflow/higher_level_reviews/not_found',
                        desc: 'returns a 404 response',
                        scopes:
      end

      response '422', 'Parameter Errors' do
        schema '$ref' => '#/components/schemas/errorModel'

        describe 'bad decisionReviewType' do
          let(:decisionReviewType) { 'invalid' }

          it_behaves_like 'rswag example',
                          desc: 'decisionReviewType must be one of: higher-level-reviews, notice-of-disagreements, supplemental-claims',
                          extract_desc: true,
                          scopes:
        end

        describe 'bad receiptDate' do
          let(:receiptDate) { '1900-01-01' }

          it_behaves_like 'rswag example',
                          cassette: 'caseflow/higher_level_reviews/bad_date',
                          desc: 'Bad receipt date for HLR',
                          extract_desc: true,
                          scopes:
        end

        describe 'missing ICN' do
          let(:icn) { '' }

          it_behaves_like 'rswag example',
                          desc: "'icn' parameter missing",
                          extract_desc: true,
                          scopes:
        end
      end

      it_behaves_like 'rswag 500 response'

      response '502', 'Unknown error' do
        it_behaves_like 'rswag example',
                        cassette: 'caseflow/higher_level_reviews/server_error',
                        desc: 'returns a 502 response',
                        scopes:
      end
    end
  end
end
# rubocop:enable RSpec/VariableName, Layout/LineLength
