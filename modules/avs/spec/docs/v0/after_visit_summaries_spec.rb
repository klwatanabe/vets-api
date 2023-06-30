require 'swagger_helper'
require Rails.root.join('spec', 'rswag_override.rb').to_s

require 'rails_helper'

describe 'After Visit Summaries', swagger_doc: 'modules/avs/app/swagger/avs/v0/swagger.json', type: :request do

  path '/after-visit-summaries' do

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
        schema type: :array,
          properties: {
            data: {
              properties: {
                id: {
                  type: :string,
                  pattern: '^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$'
                },
                path: {
                  type: :string,
                  pattern: '^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$'
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
end
