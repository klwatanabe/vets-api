# frozen_string_literal: true

require 'rails_helper'
require 'mocked_credential/service'

describe MockedAuthentication::MockedCredential::Service do
    let(:code) { '6805c923-9f37-4b47-a5c9-214391ddffd5' }
    let(:token) do
      {
        access_token: 'AmCGxDQzUAr5rPZ4NgFvUQ',
        token_type: 'Bearer',
        expires_in: 900,
        id_token: 'eyJraWQiOiJmNWNlMTIzOWUzOWQzZGE4MzZmOTYzYmNjZDg1Zjg1ZDU3ZDQzMzVjZmRjNmExNzAzOWYLOL' \
                  'QzNjFhMThiMTNjIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiI2NWY5ZjNiNS01NDQ5LTQ3YTYtYjI3Mi05Z' \
                  'DYwMTllN2MyZTMiLCJpc3MiOiJodHRwczovL2lkcC5pbnQuaWRlbnRpdHlzYW5kYm94Lmdvdi8iLCJlbWF' \
                  'pbCPzPmpvaG4uYnJhbWxleUBhZGhvY3RlYW0udXMiLCJlbHqZbF92ZXJpZmllZCI6dHJ1ZSwiZ2l2ZW5fb' \
                  'mFtZSI6IkpvaG4iLCJmYW1pb1bRfbmFtZSI6IkJyYW1sZXkiLCJiaXJ0aGRhdGUiOiIxOTg5LTAzLTI4Ii' \
                  'wic29jaWFsX3NlY3VyaXR5X251bWJlciI6IjA1Ni03Ni03MTQ5IiwidmVyaWZpZWRfYXQiOjE2MzU0NjUy' \
                  'ODYsImFjciI6Imh0dHA6Ly9pZG1hbmFnZW1lbnQuZ292L25zL2Fzc3VyYW5jZS9pYWwvMiIsIm5vbmNlIj' \
                  'oiYjIwNjc1ZjZjYmYwYWQ5M2YyNGEwMzE3YWU3Njk5OTQiLCJhdWQiOiJ1cm46Z292OmdzYTpvcGVuaWRj' \
                  'b25uZWN0LnByb2ZpbGVzOnNwOnNzbzp2YTpkZXZfc2lnbmluIiwianRpIjoicjA1aWJSenNXSjVrRnloM1' \
                  'ZuVlYtZyIsImF0X2hhc2giOiJsX0dnQmxPc2dkd0tKemc2SEFDYlJBIiwiY19oYXNoIjoiY1otX2F3OERj' \
                  'SUJGTEVpTE9QZVNFUSIsImV4cCI6MTY0NTY0MTY0NSwiaWF0IjoxNjQ1NjQwNzQ1LCJuYmYiOjE2NDU2ND' \
                  'A3NDV9.S3-8X9clNcwlH2RU5sNoYf9HXpcgVK9UGUJumhL2-3rvznrt6yGvkXvY4FuUzWEcI22muxUjbbs' \
                  'ZHjCfDImZ869NTWsI-DKohSNmNnyOom29LJRymJTn3htI5MNmpGwbmNWNuK5HgerPZblL44N1a_rqfTF4l' \
                  'ANQX0u52iIVDarcexpX0e9yS1rEPqi3PDdcwN_1tUYox4us9rgzRZaaoa4iTlFfovY7dfgo_ewqv2EDh7J' \
                  'SfJJQhFhyabkJ9HgNkkc4m0SHqztterZ6lHgIoiJdQot6wsL9pQTYzFzgHV830ltpjVUcLG5vMXw4Kqs3B' \
                  'N9tdSToHdB50Paxyfq9kg'
      }
    end
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
    
    describe '#token' do
      context 'when the request is successful' do
        it 'returns an access token' do
          subject.token(code)
        end
      end
    end

    describe '#user_info' do
      context 'when the request is successful' do
        let(:mocked_authorization_credential_information){'mocked_authorization_credential_information'}
         it 'creates a new MockCredentialInfo' do
          allow(subject).to receive(:user_info).with(token).and_return(mocked_authorization_credential_information)
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
    
