# frozen_string_literal: true

require 'rails_helper'
require 'mocked_credential/service'

describe MockedAuthentication::MockedCredential::Service do
  let(:user_info) do
    OpenStruct.new({
                     sub: user_uuid,
                     iss: 'https://idp.int.identitysandbox.gov/',
                     email: email,
                     email_verified: true,
                     given_name: first_name,
                     family_name: last_name,
                     address: address,
                     birthdate: birth_date,
                     social_security_number: ssn,
                     verified_at: 1_635_465_286
                   })
  end
  let(:first_name) { 'Bob' }
  let(:last_name) { 'User' }
  let(:birth_date) { '1993-01-01' }
  let(:ssn) { '999-11-9999' }
  let(:address) do
    {
      formatted: formatted_address,
      street_address: street,
      postal_code: postal_code,
      region: region,
      locality: locality
    }
  end
  let(:formatted_address) { "#{street}\n#{locality}, #{region} #{postal_code}" }
  let(:street) { "1 Microsoft Way\nApt 3" }
  let(:postal_code) { '11364' }
  let(:region) { 'NY' }
  let(:locality) { 'Bayside' }
  let(:multifactor) { true }
  let(:email) { 'user@test.com' }
  let(:user_uuid) { '12345678-0990-10a1-f038-2839ab281f90' }
  let(:success_callback_url) { 'http://localhost:3001/auth/login/callback?type=logingov' }
  let(:failure_callback_url) { 'http://localhost:3001/auth/login/callback?auth=fail&code=007' }
  let(:state) { 'some-state' }
  let(:acr) { 'some-acr' }

  describe '#token' do
    context 'when given a valid code' do
      let(:code) { '6805c923-9f37-4b47-a5c9-214391ddffd5' }

      it 'returns the code' do
        expect(subject.token(code)).to eq(code)
      end
    end

    context 'when given an empty string' do
      let(:code) { '' }

      it 'returns an empty string' do
        expect(subject.token(code)).to eq('')
      end
    end
  end

  describe '#user_info' do
    context 'when the request is successful' do
      let(:credential_info_code) { SecureRandom.hex }
       
      it 'creates a new MockCredentialInfo' do
        expect(subject.user_info(credential_info_code)).to be_a(OpenStruct)
      end
    end
  end

  describe '#normalized_attributes' do
    let(:client_id) { SignIn::Constants::Auth::WEB_CLIENT }
    let(:expected_standard_attributes) do
      {
        logingov_uuid: user_uuid,
        current_ial: IAL::TWO,
        max_ial: IAL::TWO,
        service_name: service_name,
        csp_email: email,
        multifactor: multifactor,
        authn_context: authn_context,
        auto_uplevel: auto_uplevel
      }
    end
    let(:credential_level) { create(:credential_level, current_ial: IAL::TWO, max_ial: IAL::TWO) }
    let(:service_name) { SAML::User::LOGINGOV_CSID }
    let(:auth_broker) { SignIn::Constants::Auth::BROKER_CODE }
    let(:authn_context) { IAL::LOGIN_GOV_IAL2 }
    let(:auto_uplevel) { false }
    let(:expected_address) do
      {
        street: street.split("\n").first,
        street2: street.split("\n").last,
        postal_code: postal_code,
        state: region,
        city: locality,
        country: country
      }
    end
    let(:country) { 'USA' }
    let(:expected_attributes) do
      expected_standard_attributes.merge({ ssn: ssn.tr('-', ''),
                                           birth_date: birth_date,
                                           first_name: first_name,
                                           last_name: last_name,
                                           address: expected_address })
    end

    it 'returns expected attributes' do
      expect(subject.normalized_attributes(user_info, credential_level)).to eq(expected_attributes)
    end
  end
end
