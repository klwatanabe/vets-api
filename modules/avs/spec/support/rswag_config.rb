# /modules/avs/spec/support/rswag_config.rb

class Avs::RswagConfig
  def config
    {
      'modules/avs/app/swagger/avs/v0/swagger.json' => {
        openapi: '3.0.1',
        info: {
          title: 'After Visit Summary',
          version: 'v0',
          termsOfService: 'https://developer.va.gov/terms-of-service',
          description: File.read(Avs::Engine.root.join('app', 'swagger', 'avs', 'v0', 'api_description.md'))
        },
        tags: [],
        components: {
          securitySchemes: {
            # TODO: update for accuracy.
            apikey: {
              type: :apiKey,
              name: :apikey,
              in: :header
            }
          },
          schemas: {}
        },
        paths: {},
        basePath: '/avs/v0/avs',
        servers: [
          {
            url: 'https://dev-api.va.gov/avs/{version}/avs',
            description: 'VA.gov API sandbox environment',
            variables: {
              version: {
                default: 'v0'
              }
            }
          }
        ]
      }
    }
  end
end