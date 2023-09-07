# frozen_string_literal: true

require 'common/client/base'
require 'dgi/enrollment/configuration'
require 'dgi/enrollment/enrollment_response'
require 'dgi/enrollment/submit_enrollment_response'
require 'dgi/service'
require 'authentication_token_service'

module MebApi
  module DGI
    module Enrollment
      class Service < MebApi::DGI::Service
        configuration MebApi::DGI::Enrollment::Configuration
        STATSD_KEY_PREFIX = 'api.dgi.status'

        def get_enrollment(claimant_id)
          with_monitoring do
            headers = request_headers
            options = { timeout: 60 }
            # response = perform(:get, enrollment_url(claimant_id), {}, headers, options)
            response = {
              body: {
                enrollment_verifications: [
                  {
                    verificationMonth: 'June 2023',
                    certifiedBeginDate: '2023-06-01',
                    certifiedEndDate: '2023-06-30',
                    certifiedThroughDate: '',
                    certificationMethod: '',
                    enrollments: [
                      {
                        facilityName: 'UNIVERSITY OF HAWAII AT HILO',
                        beginDate: '2022-09-01',
                        endDate: '2023-06-01',
                        totalCreditHours: 16,
                      },
                    ],
                    verificationResponse: 'NR',
                    createdDate: '',
                  },
                  {
                    verificationMonth: 'May 2023',
                    certifiedBeginDate: '2023-05-01',
                    certifiedEndDate: '2023-05-31',
                    certifiedThroughDate: '',
                    certificationMethod: '',
                    enrollments: [
                      {
                        facilityName: 'UNIVERSITY OF HAWAII AT HILO',
                        beginDate: '2022-09-01',
                        endDate: '2023-06-01',
                        totalCreditHours: 16,
                      },
                    ],
                    verificationResponse: 'NR',
                    createdDate: '',
                  },
                  {
                    verificationMonth: 'April 2023',
                    certifiedBeginDate: '2023-04-01',
                    certifiedEndDate: '2023-04-30',
                    certifiedThroughDate: '',
                    certificationMethod: '',
                    enrollments: [
                      {
                        facilityName: 'UNIVERSITY OF HAWAII AT HILO',
                        beginDate: '2022-09-01',
                        endDate: '2023-06-01',
                        totalCreditHours: 16,
                      },
                    ],
                    verificationResponse: 'NR',
                    createdDate: '',
                  },
                  {
                    verificationMonth: 'March 2023',
                    certifiedBeginDate: '2023-03-01',
                    certifiedEndDate: '2023-03-31',
                    certifiedThroughDate: '',
                    certificationMethod: '',
                    enrollments: [
                      {
                        facilityName: 'UNIVERSITY OF HAWAII AT HILO',
                        beginDate: '2022-09-01',
                        endDate: '2023-06-01',
                        totalCreditHours: 16,
                      },
                    ],
                    verificationResponse: 'NR',
                    createdDate: '',
                  },
                  {
                    verificationMonth: 'February 2023',
                    certifiedBeginDate: '2023-02-01',
                    certifiedEndDate: '2023-02-28',
                    certifiedThroughDate: '',
                    certificationMethod: '',
                    enrollments: [
                      {
                        facilityName: 'UNIVERSITY OF HAWAII AT HILO',
                        beginDate: '2022-09-01',
                        endDate: '2023-06-01',
                        totalCreditHours: 16,
                      },
                    ],
                    verificationResponse: 'NR',
                    createdDate: '',
                  },
                  {
                    verificationMonth: 'January 2023',
                    certifiedBeginDate: '2023-01-01',
                    certifiedEndDate: '2023-01-31',
                    certifiedThroughDate: '',
                    certificationMethod: '',
                    enrollments: [
                      {
                        facilityName: 'UNIVERSITY OF HAWAII AT HILO',
                        beginDate: '2022-09-01',
                        endDate: '2023-06-01',
                        totalCreditHours: 16,
                      },
                    ],
                    verificationResponse: 'NR',
                    createdDate: '',
                  },
                  {
                    verificationMonth: 'December 2022',
                    certifiedBeginDate: '2022-12-01',
                    certifiedEndDate: '2022-12-31',
                    certifiedThroughDate: '2022-12-31',
                    certificationMethod: 'MEB',
                    enrollments: [
                      {
                        facilityName: 'UNIVERSITY OF HAWAII AT HILO',
                        beginDate: '2022-09-01',
                        endDate: '2023-06-01',
                        totalCreditHours: 16,
                      },
                    ],
                    verificationResponse: 'Y',
                    createdDate: '',
                  },
                  {
                    verificationMonth: 'November 2022',
                    certifiedBeginDate: '2022-11-01',
                    certifiedEndDate: '2022-11-30',
                    certifiedThroughDate: '2022-11-30',
                    certificationMethod: 'MEB',
                    enrollments: [
                      {
                        facilityName: 'UNIVERSITY OF HAWAII AT HILO',
                        beginDate: '2022-09-01',
                        endDate: '2023-06-01',
                        totalCreditHours: 16,
                      },
                    ],
                    verificationResponse: 'Y',
                    createdDate: '',
                  },
                  {
                    verificationMonth: 'October 2022',
                    certifiedBeginDate: '2022-10-01',
                    certifiedEndDate: '2022-10-31',
                    certifiedThroughDate: '2022-10-31',
                    certificationMethod: 'MEB',
                    enrollments: [
                      {
                        facilityName: 'UNIVERSITY OF HAWAII AT HILO',
                        beginDate: '2022-09-01',
                        endDate: '2023-06-01',
                        totalCreditHours: 16,
                      },
                    ],
                    verificationResponse: 'Y',
                    createdDate: '',
                  },
                  {
                    verificationMonth: 'September 2022',
                    certifiedBeginDate: '2022-09-01',
                    certifiedEndDate: '2022-09-30',
                    certifiedThroughDate: '2022-09-30',
                    certificationMethod: 'MEB',
                    enrollments: [
                      {
                        facilityName: 'UNIVERSITY OF HAWAII AT HILO',
                        beginDate: '2022-09-01',
                        endDate: '2023-06-01',
                        totalCreditHours: 16,
                      },
                    ],
                    verificationResponse: 'NR',
                    createdDate: '',
                  },
                ],
                last_certified_through_date: '2023-01-31',
                payment_on_hold: false,
              }
            }
            MebApi::DGI::Enrollment::Response.new(response)
          end
        end

        def submit_enrollment(params, claimant_id)
          with_monitoring do
            headers = request_headers
            options = { timeout: 60 }
            response = perform(:post, submit_enrollment_url, format_params(params, claimant_id&.to_i), headers, options)

            MebApi::DGI::SubmitEnrollment::Response.new(response)
          end
        end

        private

        def enrollment_url(claimant_id)
          "claimant/#{claimant_id}/enrollments"
        end

        def submit_enrollment_url
          'enrollment-verification'
        end

        def request_headers
          {
            "Content-Type": 'application/json',
            Authorization: "Bearer #{MebApi::AuthenticationTokenService.call}"
          }
        end

        def format_params(params, claimant_id)
          camelized_keys = camelize_keys_for_java_service(params)

          updated_certify_requests = camelized_keys['enrollmentVerifications']['enrollmentCertifyRequests']
                                     .each do |request|
            request['claimantId'] = claimant_id
          end

          new_params_hash = {}
          new_params_hash['claimantId'] = claimant_id
          new_params_hash['enrollmentCertifyRequests'] = updated_certify_requests
          new_params_hash
        end

        def camelize_keys_for_java_service(params)
          local_params = params[0] || params

          local_params.permit!.to_h.deep_transform_keys do |key|
            if key.include?('_')
              split_keys = key.split('_')
              split_keys.collect { |key_part| split_keys[0] == key_part ? key_part : key_part.capitalize }.join
            else
              key
            end
          end
        end
      end
    end
  end
end
