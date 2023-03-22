# frozen_string_literal: true

require 'swagger_helper'
require 'rails_helper'
require_relative '../../../support/swagger_shared_components/v2'

describe 'Disability Claims', production: false, swagger_doc: Rswag::TextHelpers.new.claims_api_docs do # rubocop:disable RSpec/DescribeClass
  path '/:veteranId/526' do
    post 'Submits form 526' do
      tags 'Disability'
      operationId 'post526Claim'
      security [
        { productionOauth: ['claim.read', 'claim.write'] },
        { sandboxOauth: ['claim.read', 'claim.write'] },
        { bearer_token: [] }
      ]
      consumes 'application/json'
      produces 'application/json'
      description 'Establishes a Disability Compensation Claim in VBMS.'

      parameter name: 'veteranId',
                in: :path,
                required: true,
                type: :string,
                example: '1012667145V762142',
                description: 'ID of Veteran'

      let(:veteranId) { '1013062086V794840' } # rubocop:disable RSpec/VariableName
      let(:Authorization) { 'Bearer token' }

      describe 'Getting a successful response' do
        response '200', '526 Response' do
          it 'returns a valid 200 response' do
            one = 1
            expect(one).to eq(1)
          end
        end
      end

      describe 'Getting a 401 response' do
        response '401', 'Unauthorized' do
          it 'returns a valid 200 response' do
            one = 1
            expect(one).to eq(1)
          end
        end
      end
    end
  end

  path '/:veteranId/526/validate' do
    post 'Validates a 526 claim form submission.' do
      tags 'Disability'
      operationId 'post526ClaimValidate'
      security [
        { productionOauth: ['claim.read', 'claim.write'] },
        { sandboxOauth: ['claim.read', 'claim.write'] },
        { bearer_token: [] }
      ]
      consumes 'application/json'
      produces 'application/json'
      validate_description = <<~VERBIAGE
        Test to make sure the form submission works with your parameters.
        Submission validates against the schema returned by the GET /forms/526 endpoint.
      VERBIAGE
      description validate_description

      parameter name: 'veteranId',
                in: :path,
                required: true,
                type: :string,
                example: '1012667145V762142',
                description: 'ID of Veteran'

      let(:veteranId) { '1013062086V794840' } # rubocop:disable RSpec/VariableName
      let(:Authorization) { 'Bearer token' }

      describe 'Getting a successful response' do
        response '200', '526 Response' do
          it 'returns a valid 200 response' do
            one = 1
            expect(one).to eq(1)
          end
        end
      end

      describe 'Getting a 401 response' do
        response '401', 'Unauthorized' do
          it 'returns a valid 200 response' do
            one = 1
            expect(one).to eq(1)
          end
        end
      end
    end
  end

  path '/:veteranId/526/attachments' do
    post 'Upload documents supporting a 526 claim' do
      tags 'Disability'
      operationId 'upload526Attachments'
      security [
        { productionOauth: ['claim.read', 'claim.write'] },
        { sandboxOauth: ['claim.read', 'claim.write'] },
        { bearer_token: [] }
      ]
      consumes 'multipart/form-data'
      produces 'application/json'
      put_description = <<~VERBIAGE
        Used to attach supporting documents for a 526 claim. For wet-signature PDFs, use the PUT /forms/526/{id} endpoint.\n
        <br/><br/>\nThis endpoint accepts a document binary PDF as part of a multi-part payload (for example, attachment1, attachment2, attachment3).\n
      VERBIAGE
      description put_description

      parameter name: 'veteranId',
                in: :path,
                required: true,
                type: :string,
                example: '1012667145V762142',
                description: 'ID of Veteran'

      let(:veteranId) { '1013062086V794840' } # rubocop:disable RSpec/VariableName
      let(:Authorization) { 'Bearer token' }

      attachment_description = <<~VERBIAGE
        Attachment contents. Must be provided in binary PDF or [base64 string](https://raw.githubusercontent.com/department-of-veterans-affairs/vets-api/master/modules/claims_api/spec/fixtures/base64pdf) format and less than 11 in x 11 in.
      VERBIAGE
      parameter name: :attachment1,
                in: :formData,
                schema: {
                  type: :object,
                  properties: {
                    attachment1: {
                      type: :file,
                      description: attachment_description
                    },
                    attachment2: {
                      type: :file,
                      description: attachment_description
                    }
                  }
                }

      describe 'Getting a successful response' do
        response '200', 'upload response' do
          it 'returns a valid 200 response' do
            one = 1
            expect(one).to eq(1)
          end
        end
      end

      describe 'Getting a 401 response' do
        response '401', 'Unauthorized' do
          it 'returns a 401 response' do
            one = 1
            expect(one).to eq(1)
          end
        end
      end
    end
  end
end