# frozen_string_literal: true

require 'rails_helper'

Rspec.describe MebApi::V0::EducationBenefitsController, type: :request do
  include SchemaMatchers
  include ActiveSupport::Testing::TimeHelpers

  VCR.configure do |config|
    config.filter_sensitive_data('removed') do |interaction|
      if interaction.request.headers['Authorization']
        token = interaction.request.headers['Authorization'].first

        if (match = token.match(/^Bearer.+/) || token.match(/^token.+/))
          match[0]
        end
      end
    end

    let(:user_details) do
      {
        first_name: 'Herbert',
        last_name: 'Hoover',
        middle_name: '',
        birth_date: '1970-01-01',
        ssn: '796121200'
      }
    end

    let(:claimant_id) { 1 }
    let(:user) { build(:user, :loa3, user_details) }
    let(:headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }
    let(:faraday_response) { double('faraday_connection') }

    before do
      allow(faraday_response).to receive(:env)
      sign_in_as(user)
    end

    describe 'GET /meb_api/v0/claimant_info' do
      context 'Looks up veteran in LTS ' do
        it 'returns a 200 with claimant info' do
          VCR.use_cassette('dgi/post_claimant_info') do
            get '/meb_api/v0/claimant_info'
            expect(response).to have_http_status(:ok)
            expect(response).to match_response_schema('dgi/claimant_info_response', { strict: false })
          end
        end
      end
    end

    describe 'GET /meb_api/v0/eligibility' do
      context 'Veteran who has benefit eligibility' do
        it 'returns a 200 with eligibility data' do
          VCR.use_cassette('dgi/get_eligibility') do
            travel_to Time.zone.local(2022, 2, 9, 12) do
              get '/meb_api/v0/eligibility'
              expect(response).to have_http_status(:ok)
              expect(response).to match_response_schema('dgi/eligibility_response', { strict: false })
            end
          end
        end
      end
    end

    describe 'GET /meb_api/v0/claim_letter' do
      context 'Retrieves a veterans claim letter' do
        it 'returns a 200 status when given claimant id as parameter' do
          VCR.use_cassette('dgi/get_claim_letter') do
            get '/meb_api/v0/claim_letter'
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end

    describe 'GET /meb_api/v0/claim_status' do
      context 'Retrieves a veterans claim status' do
        it 'returns a 200 status when given claimant id as parameter' do
          VCR.use_cassette('dgi/get_claim_status') do
            get '/meb_api/v0/claim_status'
            expect(response).to have_http_status(:ok)
            expect(response).to match_response_schema('dgi/claim_status_response', { strict: false })
          end
        end
      end
    end

    describe 'GET /meb_api/v0/enrollment' do
      context 'Retrieves a veterans enrollments' do
        it 'returns a 200 status when it' do
          VCR.use_cassette('dgi/enrollment') do
            get '/meb_api/v0/enrollment', params: { claimant_id: 1 }
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end

    describe 'POST /meb_api/v0/submit_enrollment_verification' do
      context 'Creates a veterans enrollments' do
        it 'returns a 200 status when it' do
          VCR.use_cassette('dgi/submit_enrollment_verification') do
            post '/meb_api/v0/submit_enrollment_verification',
                 params: { "education_benefit":
                  { enrollment_verifications: {
                    enrollment_certify_requests: [{
                      "certified_period_begin_date": '2022-08-01',
                      "certified_period_end_date": '2022-08-31',
                      "certified_through_date": '2022-08-31',
                      "certification_method": 'MEB',
                      "app_communication": { "response_type": 'Y' }
                    }]
                  } } }
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end

    describe 'POST /meb_api/v0/duplicate_contact_info' do
      context 'retrieves data contact info ' do
        it 'returns a 200 status when it' do
          VCR.use_cassette('dgi/post_contact_info') do
            post '/meb_api/v0/duplicate_contact_info',
                 params: { "emails": [], "phones": [] }
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end

    describe 'POST /meb_api/v0/submit_claim' do
      let(:claimant_params) do
        {
          form_id: 1,
          education_benefit: {
            claimant: {
              first_name: 'Herbert',
              middle_name: 'Hoover',
              last_name: 'Hoover',
              date_of_birth: '1980-03-11',
              contact_info: {
                address_line1: '503 upper park',
                address_line2: '',
                city: 'falls church',
                zipcode: '22046',
                email_address: 'hhover@test.com',
                address_type: 'DOMESTIC',
                mobile_phone_number: '4409938894',
                country_code: 'US',
                state_code: 'VA'
              },
              notification_method: 'EMAIL'
            }
          },
          relinquished_benefit: {
            eff_relinquish_date: '2021-10-15',
            relinquished_benefit: 'Chapter30'
          },
          additional_considerations: {
            active_duty_kicker: 'N/A',
            academy_rotc_scholarship: 'YES',
            reserve_kicker: 'N/A',
            senior_rotc_scholarship: 'YES',
            active_duty_dod_repay_loan: 'YES'
          },
          comments: {
            disagree_with_service_period: false
          },
          direct_deposit: {
            account_number: '123123123123',
            account_type: 'savings',
            routing_number: '123123123'
          }
        }
      end

      context 'when successful' do
        context 'confirmation email' do
          it 'sends approved email when status is approved' do
            VCR.use_cassette('dgi/submit_claim') do
              VCR.use_cassette('dgi/get_claim_status') do
                allow(VANotify::EmailJob).to receive(:perform_async)

                post '/meb_api/v0/submit_claim', params: claimant_params

                expect(VANotify::EmailJob).to have_received(:perform_async).with(
                  'hhover@test.com',
                  'form1990meb_approved_confirmation_email_template_id',
                  {
                    'first_name' => 'HERBERT',
                    'date_submitted' => Time.zone.today.strftime('%B %d, %Y')
                  }
                )
              end
            end
          end

          it 'sends offramp email when status is not approved or denied' do
            VCR.use_cassette('dgi/submit_claim') do
              VCR.use_cassette('dgi/get_claim_status_in_progress') do
                allow(VANotify::EmailJob).to receive(:perform_async)

                post '/meb_api/v0/submit_claim', params: claimant_params

                expect(VANotify::EmailJob).to have_received(:perform_async).with(
                  'hhover@test.com',
                  'form1990meb_offramp_confirmation_email_template_id',
                  {
                    'first_name' => 'HERBERT',
                    'date_submitted' => Time.zone.today.strftime('%B %d, %Y')
                  }
                )
              end
            end
          end

          it 'sends denied email when status is denied' do
            VCR.use_cassette('dgi/submit_claim') do
              VCR.use_cassette('dgi/get_claim_status_denied') do
                allow(VANotify::EmailJob).to receive(:perform_async)

                post '/meb_api/v0/submit_claim', params: claimant_params

                expect(VANotify::EmailJob).to have_received(:perform_async).with(
                  'hhover@test.com',
                  'form1990meb_denied_confirmation_email_template_id',
                  {
                    'first_name' => 'HERBERT',
                    'date_submitted' => Time.zone.today.strftime('%B %d, %Y')
                  }
                )
              end
            end
          end

          it 'is skipped when feature flag is turned off' do
            Flipper.disable(:form1990meb_confirmation_email)

            VCR.use_cassette('dgi/submit_claim') do
              allow(VANotify::EmailJob).to receive(:perform_async)

              post '/meb_api/v0/submit_claim',
                   params: claimant_params

              expect(VANotify::EmailJob).not_to have_received(:perform_async)
            end

            Flipper.enable(:form1990meb_confirmation_email)
          end

          it 'is skipped when form email is missing' do
            contact_info_without_email = {
              **claimant_params[:education_benefit][:claimant][:contact_info],
              email_address: nil
            }
            claimant_params_without_email = {
              **claimant_params[:education_benefit],
              claimant: {
                **claimant_params[:education_benefit][:claimant],
                contact_info: { **contact_info_without_email }
              }
            }

            VCR.use_cassette('dgi/submit_claim') do
              allow(VANotify::EmailJob).to receive(:perform_async)

              post '/meb_api/v0/submit_claim',
                   params: claimant_params_without_email

              expect(VANotify::EmailJob).not_to have_received(:perform_async)
            end
          end
        end
      end

      context 'when unsuccessful' do
        context 'confirmation email' do
          it 'does not send' do
            VCR.use_cassette('dgi/submit_claim_failure') do
              allow(VANotify::EmailJob).to receive(:perform_async)

              response = post '/meb_api/v0/submit_claim',
                              params: claimant_params

              expect(response).to be(503)
              expect(VANotify::EmailJob).not_to have_received(:perform_async)
            end
          end
        end
      end
    end
  end
end
