# frozen_string_literal: true

require 'common/client/base'
require 'dgi/automation/configuration'
require 'dgi/service'
require 'dgi/automation/claimant_response'
require 'authentication_token_service'

module MebApi
  module DGI
    module Automation
      class Service < MebApi::DGI::Service
        configuration MebApi::DGI::Automation::Configuration
        STATSD_KEY_PREFIX = 'api.dgi.automation'

        def get_claimant_info(type = 'Chapter33')
          with_monitoring do
            headers = request_headers
            options = { timeout: 60 }
            # raw_response = perform(:post, end_point(type), { ssn: @user.ssn.to_s }.to_json, headers, options)

            raw_response = {
              body: {
                claimant: {
                  claimantId: 300000000000001,
                  suffix: 'Jr.',
                  dateOfBirth: '1988-10-01',
                  firstName: 'Teressa',
                  lastName: 'Harber',
                  middleName: 'Estefana',
                  notificationMethod: 'TEXT',
                  contactInfo: {
                    addressLine1: '23082 Xavier Union',
                    addressLine2: 'Apt. 498',
                    city: 'Lake Stephanville',
                    zipcode: '40638-9651',
                    emailAddress: 'test@test.com',
                    addressType: 'DOMESTIC',
                    mobilePhoneNumber: '5401113337',
                    homePhoneNumber: '5401114448',
                    countryCode: 'US',
                    stateCode: 'KS',
                  },
                  preferredContact: '',
                },
                serviceData: [
                  {
                    branchOfService: 'Marine Corps',
                    beginDate: '2009-01-01',
                    endDate: '2019-12-01',
                    characterOfService: 'Honorable',
                    reasonForSeparation: 'Expiration Term Of Service',
                    exclusionPeriods: [],
                    trainingPeriods: [],
                  },
                ],
                toeSponsors: '',
              }
            }
            MebApi::DGI::Automation::ClaimantResponse.new(200, raw_response)
          end
        end

        private

        def end_point(type)
          "claimType/#{type}/claimants"
        end

        def request_headers
          {
            Authorization: "Bearer #{MebApi::AuthenticationTokenService.call}"
          }
        end
      end
    end
  end
end
