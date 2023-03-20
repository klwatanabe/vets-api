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
  let(:first_name) { 'some-first-name' }
  let(:last_name) { 'some-last-name' }
  let(:birth_date) { 'some-birth-date' }
  let(:ssn) { 'some-ssn' }
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
  let(:postal_code) { 'some-postal-code' }
  let(:region) { 'some-region' }
  let(:locality) { 'some-locality' }
  let(:multifactor) { true }
  let(:email) { 'some-email' }
  let(:user_uuid) { 'some-user-uuid' }

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
