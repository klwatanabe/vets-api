# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/helpers/iam_session_helper'

RSpec.describe 'check in', type: :request do
  let(:attributes) { response.parsed_body.dig('data', 'attributes') }
  let(:mpi_profile) { build(:mpi_profile_response) }
  let(:user) { build(:user, :loa3, mpi_profile:) }

  describe 'POST /mobile/v0/appointments/check-in' do
    before do
      allow_any_instance_of(User).to receive(:mpi_profile).and_return(mpi_profile)
      iam_sign_in(user)
    end

    it 'correctly updates check in when 200' do
      VCR.use_cassette('chip/authenticated_check_in/post_check_in_200') do
        VCR.use_cassette('check_in/chip/token/token_200') do
          post '/mobile/v0/appointments/check-in', headers: iam_headers,
                                                   params: { 'appointmentIEN' => '516', 'locationId' => '516' }
        end
      end

      expect(attributes['message']).to match('success with appointmentIen: test-appt-ien, patientDfn: test-patient-ien, stationNo: test-station-no')
    end

    it 'shows error when nil appointmentIEN' do
      VCR.use_cassette('chip/authenticated_check_in/post_check_in_invalid_appointment_200') do
        VCR.use_cassette('check_in/chip/token/token_200') do
          post '/mobile/v0/appointments/check-in', headers: iam_headers,
                                                   params: { 'appointmentIEN' => nil, 'locationId' => '516' }
        end
      end

      expect(response.status).to eq(400)
      expect(response.parsed_body.dig('errors', 0, 'title')).to match('Missing parameter')
    end

    it 'shows error when nil locationId' do
      VCR.use_cassette('chip/authenticated_check_in/post_check_in_invalid_appointment_200') do
        VCR.use_cassette('check_in/chip/token/token_200') do
          post '/mobile/v0/appointments/check-in', headers: iam_headers,
               params: { 'appointmentIEN' => '516', 'locationId' => nil }
        end
      end

      expect(response.status).to eq(400)
      expect(response.parsed_body.dig('errors', 0, 'title')).to match('Missing parameter')
    end
  end
end
