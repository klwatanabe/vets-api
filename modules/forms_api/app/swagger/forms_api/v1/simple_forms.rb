module Swagger
  module Requests
    class SimpleForms
      include Swagger::Blocks

      swagger_path 'forms_api/v1/simple_forms' do
        operation :post do
          extend Swagger::Responses::AuthenticationError

          key :description, 'Accepts form data'
          key :operationId, 'submit'
          key :tags, %w[
            simple_forms
          ]

          parameter :authorization
          parameter :data

          response 200 do
            key :description, 'Response is OK'
            schema do
              key :'$ref', :data
            end
          end
        end
      end
    end
  end
end