require 'swagger_helper'
require Rails.root.join('spec', 'rswag_override.rb').to_s

require 'rails_helper'

describe 'After Visit Summaries', swagger_doc: 'modules/avs/app/swagger/avs/v0/swagger.json', type: :request do

  path '/avs' do

    let(:apikey) { 'apikey' }

    get 'Returns information about After Visit Summaries matching the given parameters' do
      tags ''

      operationId 'after-visit-summaries-index'

      security [
        { apikey: [] }
      ]

      consumes 'application/json'
      produces 'application/json'

      # parameter name: :stationNumber, in: :query, type: :string, description: 'VA Station Number'

      response '200', 'Array of After Visit Summaries' do
        schema type: :object,
          properties: {
            data: {
              properties: {
                id: {
                  type: :integer,
                  pattern: '^[0-9]*$'
                },
                path: {
                  type: :string,
                  pattern: '^[a-zA-Z0-9\-/]*/[0-9]*$'
                },
              },
            }
          },
          required: ['data']

        # let(:stationNumber) { FactoryBot.create(:avs_v0).stationNumber }


        before do |example|
          submit_request(example.metadata)
        end

        it 'returns a 200 response' do |example|
          assert_response_matches_metadata(example.metadata)
        end

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
      end
    end
  end

  path '/avs/{id}' do

    let(:apikey) { 'apikey' }
    let(:id) { '123' }

    get 'Returns After Visit Summary' do
      tags ''

      operationId 'after-visit-summaries-show'

      security [
        { apikey: [] }
      ]

      produces 'application/json'

      parameter name: :id, in: :path, type: :integer, description: 'AVS ID'

      response '200', 'After Visit Summary' do
        schema type: :object,
          properties: {
            data: {
              properties: {
                id: {
                  type: :integer,
                  pattern: '^[0-9]*$'
                },
                path: {
                  type: :string,
                  pattern: '^[a-zA-Z0-9\-/]*/[0-9]*$'
                },
              },
            }
          },
          required: ['data']


        before do |example|
          submit_request(example.metadata)
        end

        it 'returns a 200 response' do |example|
          assert_response_matches_metadata(example.metadata)
        end

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
      end
    end
  end
end
