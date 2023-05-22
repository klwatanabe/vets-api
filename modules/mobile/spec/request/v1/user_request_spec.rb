# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/iam_session_helper'
require_relative '../../support/matchers/json_schema_matcher'
require 'common/client/errors'

RSpec.describe 'user', type: :request do
  include JsonSchemaMatchers

  describe 'GET /mobile/v1/user' do
    before do
      allow_any_instance_of(IAMUser).to receive(:idme_uuid).and_return('b2fab2b5-6af0-45e1-a9e2-394347af91ef')
      iam_sign_in(build(:iam_user))
    end

    before(:all) do
      @original_cassette_dir = VCR.configure(&:cassette_library_dir)
      VCR.configure { |c| c.cassette_library_dir = 'modules/mobile/spec/support/vcr_cassettes' }
    end

    after(:all) { VCR.configure { |c| c.cassette_library_dir = @original_cassette_dir } }

    context 'with no upstream errors' do
      before do
        VCR.use_cassette('payment_information/payment_information') do
          VCR.use_cassette('user/get_facilities') do
            VCR.use_cassette('va_profile/demographics/demographics') do
              get '/mobile/v1/user', headers: iam_headers
            end
          end
        end
      end

      let(:attributes) { response.parsed_body.dig('data', 'attributes') }

      it 'returns an ok response' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns a user profile response with the expected schema' do
        expect(response.body).to match_json_schema('v1/user')
      end

      it 'includes the users names' do
        expect(attributes['profile']).to include(
          'firstName' => 'GREG',
          'preferredName' => 'SAM',
          'middleName' => 'A',
          'lastName' => 'ANDERSON'
        )
      end

      it 'includes the users gender identity' do
        expect(attributes['profile']).to include(
          'genderIdentity' => 'F'
        )
      end

      it 'includes the users sign-in email' do
        expect(attributes['profile']).to include(
          'signinEmail' => 'va.api.user+idme.008@gmail.com'
        )
      end

      it 'includes the users contact email id' do
        expect(attributes.dig('profile', 'contactEmail', 'id')).to eq(456)
      end

      it 'includes the users contact email addrss' do
        expect(attributes.dig('profile', 'contactEmail', 'emailAddress')).to match(/person\d+@example.com/)
      end

      it 'includes the users birth date' do
        expect(attributes['profile']).to include(
          'birthDate' => '1970-08-12'
        )
      end

      it 'includes the expected residential address' do
        expect(attributes['profile']).to include(
          'residentialAddress' => {
            'id' => 123,
            'addressLine1' => '140 Rock Creek Rd',
            'addressLine2' => nil,
            'addressLine3' => nil,
            'addressPou' => 'RESIDENCE/CHOICE',
            'addressType' => 'DOMESTIC',
            'city' => 'Washington',
            'countryCodeIso3' => 'USA',
            'internationalPostalCode' => nil,
            'province' => nil,
            'stateCode' => 'DC',
            'zipCode' => '20011',
            'zipCodeSuffix' => nil
          }
        )
      end

      it 'includes the expected mailing address' do
        expect(attributes['profile']).to include(
          'mailingAddress' => {
            'id' => 124,
            'addressLine1' => '140 Rock Creek Rd',
            'addressLine2' => nil,
            'addressLine3' => nil,
            'addressPou' => 'CORRESPONDENCE',
            'addressType' => 'DOMESTIC',
            'city' => 'Washington',
            'countryCodeIso3' => 'USA',
            'internationalPostalCode' => nil,
            'province' => nil,
            'stateCode' => 'DC',
            'zipCode' => '20011',
            'zipCodeSuffix' => nil
          }
        )
      end

      it 'includes a home phone number' do
        expect(attributes['profile']['homePhoneNumber']).to include(
          {
            'id' => 789,
            'areaCode' => '303',
            'countryCode' => '1',
            'extension' => nil,
            'phoneNumber' => '5551234',
            'phoneType' => 'HOME'
          }
        )
      end

      it 'includes a mobile phone number' do
        expect(attributes['profile']['mobilePhoneNumber']).to include(
          {
            'id' => 790,
            'areaCode' => '303',
            'countryCode' => '1',
            'extension' => nil,
            'phoneNumber' => '5551234',
            'phoneType' => 'MOBILE'
          }
        )
      end

      it 'includes a work phone number' do
        expect(attributes['profile']['workPhoneNumber']).to include(
          {
            'id' => 791,
            'areaCode' => '303',
            'countryCode' => '1',
            'extension' => nil,
            'phoneNumber' => '5551234',
            'phoneType' => 'WORK'
          }
        )
      end

      it 'includes sign-in service' do
        expect(attributes['profile']['signinService']).to eq('IDME')
      end

      it 'includes the service the user has access to' do
        expect(attributes['authorizedServices']).to eq(
          %w[
            appeals
            appointments
            claims
            directDepositBenefits
            disabilityRating
            lettersAndDocuments
            militaryServiceHistory
            paymentHistory
            userProfileUpdate
            scheduleAppointments
            directDepositBenefitsUpdate
          ]
        )
      end

      it 'includes a complete list of mobile api services (even if the user does not have access to them)' do
        expect(JSON.parse(response.body).dig('meta', 'availableServices')).to eq(
          %w[
            appeals
            appointments
            claims
            directDepositBenefits
            disabilityRating
            lettersAndDocuments
            militaryServiceHistory
            paymentHistory
            userProfileUpdate
            secureMessaging
            scheduleAppointments
            prescriptions
          ]
        )
      end

      it 'includes a health attribute with user facilities and is_cerner_patient' do
        expect(attributes['health']).to include(
          {
            'isCernerPatient' => true,
            'facilities' => [
              {
                'facilityId' => '757',
                'isCerner' => true,
                'facilityName' => 'Cheyenne VA Medical Center'
              },
              {
                'facilityId' => '358',
                'isCerner' => false,
                'facilityName' => 'COLUMBUS VAMC'
              }
            ]
          }
        )
      end

      context 'when user object birth_date is nil' do
        before do
          iam_sign_in(FactoryBot.build(:iam_user, :no_birth_date))
          VCR.use_cassette('payment_information/payment_information') do
            VCR.use_cassette('user/get_facilities_no_ids', match_requests_on: %i[method uri]) do
              VCR.use_cassette('va_profile/demographics/demographics') do
                get '/mobile/v1/user', headers: iam_headers
              end
            end
          end
        end

        it 'returns a nil birthdate' do
          expect(response).to have_http_status(:ok)
          expect(attributes['profile']).to include(
            'birthDate' => nil
          )
        end
      end

      context 'with a user who does not have access to evss and is not using Lighthouse Letters service' do
        before do
          Flipper.disable(:mobile_lighthouse_letters)
          iam_sign_in(FactoryBot.build(:iam_user, :no_edipi_id))
          VCR.use_cassette('payment_information/payment_information') do
            VCR.use_cassette('user/get_facilities_no_ids', match_requests_on: %i[method uri]) do
              VCR.use_cassette('va_profile/demographics/demographics') do
                get '/mobile/v1/user', headers: iam_headers
              end
            end
          end
        end

        it 'does not include edipi services (claims, direct deposit, letters)' do
          expect(attributes['authorizedServices']).to eq(
            %w[
              appeals
              appointments
              militaryServiceHistory
              paymentHistory
              userProfileUpdate
            ]
          )
        end
      end

      context 'with a user who has access to evss but not ppiu (not idme)' do
        before do
          user = FactoryBot.build(:iam_user, :no_multifactor)
          iam_sign_in(user)
          VCR.use_cassette('payment_information/payment_information') do
            VCR.use_cassette('user/get_facilities', match_requests_on: %i[method uri]) do
              VCR.use_cassette('va_profile/demographics/demographics') do
                get '/mobile/v1/user', headers: iam_headers
              end
            end
          end
        end

        it 'does not include directDepositBenefits in the authorized services list' do
          expect(attributes['authorizedServices']).to eq(
            %w[
              appeals
              appointments
              claims
              disabilityRating
              lettersAndDocuments
              militaryServiceHistory
              paymentHistory
              userProfileUpdate
              scheduleAppointments
            ]
          )
        end
      end

      context 'with a user that has mhv sign-in service' do
        before do
          allow_any_instance_of(MHVAccountTypeService).to receive(:mhv_account_type).and_return('Premium')
          current_user = build(:iam_user, :mhv)
          iam_sign_in(current_user)
          VCR.use_cassette('payment_information/payment_information') do
            VCR.use_cassette('user/get_facilities') do
              VCR.use_cassette('va_profile/demographics/demographics') do
                get '/mobile/v0/user', headers: iam_headers
              end
            end
          end
        end

        it 'includes prescriptions in authorized services' do
          expect(attributes['authorizedServices']).to eq(
            %w[
              appeals
              appointments
              claims
              disabilityRating
              lettersAndDocuments
              militaryServiceHistory
              paymentHistory
              userProfileUpdate
              scheduleAppointments
              prescriptions
            ]
          )
        end
      end

      context 'with a user who does not have access to bgs' do
        before do
          Flipper.disable(:mobile_lighthouse_letters)
          iam_sign_in(FactoryBot.build(:iam_user, :no_participant_id))
          VCR.use_cassette('payment_information/payment_information') do
            VCR.use_cassette('user/get_facilities_no_ids', match_requests_on: %i[method uri]) do
              VCR.use_cassette('va_profile/demographics/demographics') do
                get '/mobile/v1/user', headers: iam_headers
              end
            end
          end
        end

        it 'does not include paymentHistory' do
          expect(attributes['authorizedServices']).to eq(
            %w[
              appeals
              appointments
              militaryServiceHistory
              userProfileUpdate
            ]
          )
        end
      end

      context 'with a user who does not have access to schedule appointments' do
        context 'due to not having any registered faclities' do
          let(:user_request) do
            iam_sign_in(FactoryBot.build(:iam_user, :no_vha_facilities))
            VCR.use_cassette('payment_information/payment_information') do
              VCR.use_cassette('user/get_facilities_no_ids', match_requests_on: %i[method uri]) do
                VCR.use_cassette('va_profile/demographics/demographics') do
                  get '/mobile/v0/user', headers: iam_headers
                end
              end
            end
          end

          it 'authorized services does not include scheduleAppointments' do
            user_request
            expect(attributes['authorizedServices']).not_to include('scheduleAppointments')
          end

          it 'increments statsd' do
            expect do
              user_request
            end.to trigger_statsd_increment('mobile.schedule_appointment.policy.failure', times: 1)
          end
        end

        context 'due to not being LOA3' do
          let(:user_request) do
            iam_sign_in(FactoryBot.build(:iam_user, :loa2))
            VCR.use_cassette('payment_information/payment_information') do
              VCR.use_cassette('user/get_facilities_no_ids', match_requests_on: %i[method uri]) do
                VCR.use_cassette('va_profile/demographics/demographics') do
                  get '/mobile/v0/user', headers: iam_headers
                end
              end
            end
          end

          it 'authorized services does not include scheduleAppointments' do
            user_request
            expect(attributes['authorizedServices']).not_to include('scheduleAppointments')
          end

          it 'increments statsd' do
            expect do
              user_request
            end.to trigger_statsd_increment('mobile.schedule_appointment.policy.failure', times: 1)
          end
        end
      end

      context 'with a user who does have access to schedule appointments' do
        let(:user_request) do
          VCR.use_cassette('payment_information/payment_information') do
            VCR.use_cassette('user/get_facilities', match_requests_on: %i[method uri]) do
              VCR.use_cassette('va_profile/demographics/demographics') do
                get '/mobile/v0/user', headers: iam_headers
              end
            end
          end
        end

        it 'authorized services does include scheduleAppointments' do
          user_request
          expect(attributes['authorizedServices']).to include('scheduleAppointments')
        end

        it 'increments statsd' do
          expect do
            user_request
          end.to trigger_statsd_increment('mobile.schedule_appointment.policy.success', times: 1)
        end
      end
    end

    context 'when the upstream va profile service returns a 502' do
      before do
        allow_any_instance_of(VAProfile::ContactInformation::Service).to receive(:get_person).and_raise(
          Common::Exceptions::BackendServiceException.new('VET360_502')
        )
      end

      it 'returns a service unavailable error' do
        VCR.use_cassette('user/get_facilities', match_requests_on: %i[method uri]) do
          get '/mobile/v1/user', headers: iam_headers
        end

        expect(response).to have_http_status(:bad_gateway)
        expect(response.body).to match_json_schema('errors')
      end
    end

    context 'when the upstream va profile service returns a 404' do
      before do
        allow_any_instance_of(VAProfile::ContactInformation::Service).to receive(:get_person).and_raise(
          Faraday::ResourceNotFound.new('the resource could not be found')
        )
      end

      it 'returns a record not found error' do
        VCR.use_cassette('user/get_facilities', match_requests_on: %i[method uri]) do
          get '/mobile/v1/user', headers: iam_headers
        end

        expect(response).to have_http_status(:not_found)
        expect(response.body).to match_json_schema('errors')
        expect(response.parsed_body).to eq(
          {
            'errors' => [
              {
                'title' => 'Record not found',
                'detail' => 'The record identified by 1 could not be found',
                'code' => '404',
                'status' => '404'
              }
            ]
          }
        )
      end
    end

    context 'when the va profile service throws an argument error' do
      before do
        allow_any_instance_of(VAProfile::ContactInformation::Service).to receive(:get_person).and_raise(
          ArgumentError.new
        )
      end

      it 'returns a bad gateway error' do
        get '/mobile/v1/user', headers: iam_headers

        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to match_json_schema('errors')
      end
    end

    context 'when the va profile service throws an client error' do
      before do
        allow_any_instance_of(VAProfile::ContactInformation::Service).to receive(:get_person).and_raise(
          Common::Client::Errors::ClientError.new
        )
      end

      it 'returns a bad gateway error' do
        VCR.use_cassette('user/get_facilities', match_requests_on: %i[method uri]) do
          get '/mobile/v1/user', headers: iam_headers
        end

        expect(response).to have_http_status(:bad_gateway)
        expect(response.body).to match_json_schema('errors')
      end
    end

    context 'when the ppiu service throws a 500' do
      let(:authorized_services) { response.parsed_body.dig('data', 'attributes', 'authorizedServices') }

      it 'returns an ok response with no directDepositBenefitsUpdate permission' do
        VCR.use_cassette('payment_information/service_error_500') do
          VCR.use_cassette('user/get_facilities') do
            VCR.use_cassette('va_profile/demographics/demographics') do
              get '/mobile/v1/user', headers: iam_headers
            end
          end
        end

        expect(response).to have_http_status(:ok)
        expect(authorized_services).to eq(%w[appeals
                                             appointments
                                             claims
                                             directDepositBenefits
                                             disabilityRating
                                             lettersAndDocuments
                                             militaryServiceHistory
                                             paymentHistory
                                             userProfileUpdate
                                             scheduleAppointments])
      end
    end

    context 'when the ppiu service throws a 502' do
      before do
        VCR.use_cassette('payment_information/service_error_502') do
          VCR.use_cassette('user/get_facilities') do
            VCR.use_cassette('va_profile/demographics/demographics') do
              get '/mobile/v1/user', headers: iam_headers
            end
          end
        end
      end

      let(:authorized_services) { response.parsed_body.dig('data', 'attributes', 'authorizedServices') }

      it 'returns an ok response with no directDepositBenefitsUpdate permission' do
        expect(response).to have_http_status(:ok)
        expect(authorized_services).to eq(%w[appeals
                                             appointments
                                             claims
                                             directDepositBenefits
                                             disabilityRating
                                             lettersAndDocuments
                                             militaryServiceHistory
                                             paymentHistory
                                             userProfileUpdate
                                             scheduleAppointments])
      end
    end

    describe 'appointments precaching' do
      context 'with mobile_precache_appointments flag on' do
        before { Flipper.enable(:mobile_precache_appointments) }

        it 'kicks off a pre cache appointments job' do
          expect(Mobile::V0::PreCacheAppointmentsJob).to receive(:perform_async).once
          VCR.use_cassette('payment_information/payment_information') do
            VCR.use_cassette('user/get_facilities', match_requests_on: %i[method uri]) do
              VCR.use_cassette('va_profile/demographics/demographics') do
                get '/mobile/v1/user', headers: iam_headers
              end
            end
          end
        end
      end

      context 'with mobile_precache_appointments flag off' do
        before { Flipper.disable(:mobile_precache_appointments) }

        after { Flipper.enable(:mobile_precache_appointments) }

        it 'does not kick off a pre cache appointments job' do
          expect(Mobile::V0::PreCacheAppointmentsJob).not_to receive(:perform_async)
          VCR.use_cassette('payment_information/payment_information') do
            VCR.use_cassette('user/get_facilities', match_requests_on: %i[method uri]) do
              get '/mobile/v1/user', headers: iam_headers
            end
          end
        end
      end
    end

    context 'empty get_facility test' do
      before do
        VCR.use_cassette('payment_information/payment_information') do
          VCR.use_cassette('user/get_facilities_empty', match_requests_on: %i[method uri]) do
            VCR.use_cassette('va_profile/demographics/demographics') do
              get '/mobile/v1/user', headers: iam_headers
            end
          end
        end
      end

      let(:attributes) { response.parsed_body.dig('data', 'attributes') }

      it 'returns empty appropriate facilities list' do
        expect(attributes['health']).to include(
          {
            'isCernerPatient' => true,
            'facilities' => [
              {
                'facilityId' => '757',
                'isCerner' => true,
                'facilityName' => ''
              },
              {
                'facilityId' => '358',
                'isCerner' => false,
                'facilityName' => ''
              }
            ]
          }
        )
      end
    end

    context 'with no upstream errors for logingov user' do
      before do
        iam_sign_in(FactoryBot.build(:iam_user, :logingov))
        VCR.use_cassette('payment_information/payment_information') do
          VCR.use_cassette('user/get_facilities') do
            VCR.use_cassette('va_profile/demographics/demographics') do
              get '/mobile/v1/user', headers: iam_headers
            end
          end
        end
      end

      let(:attributes) { response.parsed_body.dig('data', 'attributes') }

      it 'returns an ok response' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns a user profile response with the expected schema' do
        expect(response.body).to match_json_schema('v1/user')
      end

      it 'includes sign-in service' do
        expect(attributes['profile']['signinService']).to eq('LOGINGOV')
      end

      it 'includes the service the user has access to' do
        expect(attributes['authorizedServices']).to eq(
          %w[
            appeals
            appointments
            claims
            directDepositBenefits
            disabilityRating
            lettersAndDocuments
            militaryServiceHistory
            paymentHistory
            userProfileUpdate
            scheduleAppointments
            directDepositBenefitsUpdate
          ]
        )
      end
    end
  end
end
