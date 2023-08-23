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

    it 'correctly updates check in' do
      post '/mobile/v0/appointments/check-in', headers: iam_headers, params: { 'appointmentIEN' => '516', 'locationId' => '516' }
    end
  end
end
