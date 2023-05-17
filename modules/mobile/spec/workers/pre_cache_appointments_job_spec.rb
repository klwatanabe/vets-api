# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/iam_session_helper'

RSpec.describe Mobile::V0::PreCacheAppointmentsJob, type: :job do
  let(:user) { create(:user, :loa3, icn: '1012846043V576341') }

  let(:mock_facility) do
    known_ids = %w[983 984 442 508 983GC 983GB 688 516 984GA 983GD 984GD 438 620GB 984GB 442GB 442GC 442GD 983QA 984GC 983QE 983HK 999AA]
    mock_facility = { id: '983',
                      name: 'Cheyenne VA Medical Center',
                      timezone: {
                        zoneId: 'America/Denver',
                        abbreviation: "MDT"
                      },
                      physical_address: { type: 'physical',
                                          line: ['2360 East Pershing Boulevard'],
                                          city: 'Cheyenne',
                                          state: 'WY',
                                          postal_code: '82001-5356' },
                      lat: 41.148026,
                      long: -104.786255,
                      phone: { main: '307-778-7550' },
                      url: nil,
                      code: nil }

    known_ids.each do |facility_id|
      allow(Rails.cache).to receive(:fetch).with("vaos_facility_#{facility_id}", { :expires_in => 12.hours }).and_return(mock_facility.merge(id: facility_id))
    end

    allow_any_instance_of(Mobile::V2::Appointments::Proxy).to receive(:get_facility).and_return(mock_facility)
  end

  before do
    Sidekiq::Worker.clear_all
    allow_any_instance_of(VAOS::UserService).to receive(:session).and_return('stubbed_token')
  end

  before(:all) do
    @original_cassette_dir = VCR.configure(&:cassette_library_dir)
    VCR.configure { |c| c.cassette_library_dir = 'modules/mobile/spec/support/vcr_cassettes' }
  end

  after(:all) { VCR.configure { |c| c.cassette_library_dir = @original_cassette_dir } }

  describe '.perform_async' do
    before { Timecop.freeze(Time.zone.parse('2022-01-01T19:25:00Z')) }

    after { Timecop.return }

    it 'caches the user\'s appointments' do
      VCR.use_cassette('appointments/VAOS_v2/get_facility_200', match_requests_on: %i[method uri]) do
        VCR.use_cassette('appointments/VAOS_v2/get_clinic_200', match_requests_on: %i[method uri]) do
          VCR.use_cassette('appointments/VAOS_v2/get_appointment_200', match_requests_on: %i[method uri]) do
            expect(Mobile::V0::Appointment.get_cached(user)).to be_nil

            subject.perform(user.uuid)

            expect(Mobile::V0::Appointment.get_cached(user)).not_to be_nil
          end
        end
      end
    end

    it 'doesn\'t caches the user\'s appointments when failures are encountered' do
      VCR.use_cassette('appointments/VAOS_v2/get_facility_200', match_requests_on: %i[method uri]) do
        VCR.use_cassette('appointments/VAOS_v2/get_clinic_200', match_requests_on: %i[method uri]) do
          VCR.use_cassette('appointments/VAOS_v2/get_appointment_200_partial_error',
                           match_requests_on: %i[method uri]) do
            expect(Mobile::V0::Appointment.get_cached(user)).to be_nil

            subject.perform(user.uuid)

            expect(Mobile::V0::Appointment.get_cached(user)).to be_nil
          end
        end
      end
    end

    context 'with mobile_precache_appointments flag off' do
      before { Flipper.disable(:mobile_precache_appointments) }

      after { Flipper.enable(:mobile_precache_appointments) }

      it 'does nothing' do
        expect do
          subject.perform(user.uuid)
        end.not_to raise_error
        expect(Mobile::V0::Appointment.get_cached(user)).to be_nil
      end
    end

    context 'with IAM user' do
      let(:user) { FactoryBot.build(:iam_user) }

      before do
        allow_any_instance_of(IAMUser).to receive(:icn).and_return('1012846043V576341')
        iam_sign_in(user)
      end

      it 'caches the user\'s appointments' do
        VCR.use_cassette('appointments/VAOS_v2/get_facility_200', match_requests_on: %i[method uri]) do
          VCR.use_cassette('appointments/VAOS_v2/get_clinic_200', match_requests_on: %i[method uri]) do
            VCR.use_cassette('appointments/VAOS_v2/get_appointment_200', match_requests_on: %i[method uri]) do
              expect(Mobile::V0::Appointment.get_cached(user)).to be_nil

              subject.perform(user.uuid)

              expect(Mobile::V0::Appointment.get_cached(user)).not_to be_nil
            end
          end
        end
      end
    end

    context 'when user is not found' do
      it 'caches the expected claims and appeals' do
        expect do
          subject.perform('iamtheuuidnow')
        end.to raise_error(described_class::MissingUserError, 'iamtheuuidnow')
        expect(Mobile::V0::Appointment.get_cached(user)).to be_nil
      end
    end
  end
end
