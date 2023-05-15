# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VAOS::V2::AppointmentsController, type: :controller do
  let(:va_booked_request_body) do
    FactoryBot.build(:appointment_form_v2, :va_booked).attributes
  end

  # mock_facility = {
  #   test: 'test',
  #   timezone: {
  #     time_zone_id: 'America/New_York'
  #   }
  # }

  describe '#add_timezone_offset' do
    let(:desired_date) { '2022-09-21T00:00:00+00:00'.to_datetime }

    context 'with a date and timezone' do
      it 'adds the timezone offset to the date' do
        date_with_offset = subject.send(:add_timezone_offset, desired_date, 'America/New_York')
        expect(date_with_offset.to_s).to eq('2022-09-21T00:00:00-04:00')
      end
    end

    context 'with a date and nil timezone' do
      it 'leaves the date as is' do
        date_with_offset = subject.send(:add_timezone_offset, desired_date, nil)
        expect(date_with_offset.to_s).to eq(desired_date.to_s)
      end
    end

    context 'with a nil date' do
      it 'throws a ParameterMissing exception' do
        expect do
          subject.send(:add_timezone_offset, nil, 'America/New_York')
        end.to raise_error(Common::Exceptions::ParameterMissing)
      end
    end
  end

  # xdescribe '#get_facility_timezone' do
  #   let(:facility_location_id) { '983' }
  #   let(:facility_error_msg) { 'Error fetching facility details' }

  #   context 'with a facility location id' do
  #     it 'returns the facility timezone' do
  #       allow_any_instance_of(VAOS::V2::AppointmentsController).to receive(:get_facility).and_return(mock_facility)
  #       timezone = subject.send(:get_facility_timezone, facility_location_id)
  #       expect(timezone).to eq('America/New_York')
  #     end
  #   end

  #   context 'with an internal server error from the facilities call' do
  #     it 'returns nil for the timezone' do
  # rubocop:disable Layout/LineLength
  #       allow_any_instance_of(VAOS::V2::AppointmentsController).to receive(:get_facility).and_return(facility_error_msg)
  # rubocop:enable Layout/LineLength
  #       timezone = subject.send(:get_facility_timezone, facility_location_id)
  #       expect(timezone).to eq(nil)
  #     end
  #   end
  # end

  # xdescribe '#convert_utc_to_local_time' do
  #   let(:start_datetime) { '2021-09-02T14:00:00Z'.to_datetime }

  #   context 'with a date and timezone' do
  #     it 'converts UTC to local time' do
  #       local_time = subject.send(:convert_utc_to_local_time, start_datetime, 'America/New_York')
  #       expect(local_time.to_s).to eq(start_datetime.to_time.utc.in_time_zone('America/New_York').to_datetime.to_s)
  #     end
  #   end

  #   context 'with a date and no timezone' do
  #     it 'does not convert UTC to local time' do
  #       local_time = subject.send(:convert_utc_to_local_time, start_datetime, nil)
  #       expect(local_time.to_s).to eq(start_datetime.to_s)
  #     end
  #   end

  #   context 'with a nil date' do
  #     it 'throws a ParameterMissing exception' do
  #       expect do
  #         subject.send(:convert_utc_to_local_time, nil, 'America/New_York')
  #       end.to raise_error(Common::Exceptions::ParameterMissing)
  #     end
  #   end
  # end

  describe '#modify_desired_date' do
    context 'with a request body and facility timezone' do
      it 'updates the direct scheduled appt desired date with facilities time zone offset' do
        subject.send(:modify_desired_date, va_booked_request_body, 'America/Denver')
        expect(va_booked_request_body[:extension][:desired_date].to_s).to eq('2022-11-30T00:00:00-07:00')
      end
    end
  end

  describe '#find_provider_name' do
    it 'returns nil when no provider name is given' do
      mock =
        { practitioners: [{ identifier: [{ system: 'http://hl7.org/fhir/sid/us-npi', value: '1528231610' }] }] }
      provider_name = subject.send(:find_provider_name, mock)
      expect(provider_name).to eq(nil)
    end

    it 'returns the provider name when provider name is given' do
      mock =
        { practitioners: [{ identifier: [{ system: 'http://hl7.org/fhir/sid/us-npi', value: '1528231610' }],
                            name: { family: 'Dubbaka', given: ['Naveen'] } }] }
      provider_name = subject.send(:find_provider_name, mock)
      expect(provider_name).to eq('Naveen Dubbaka')
    end
  end

  describe '#find_practice_name' do
    it 'returns nil when no practice name is given' do
      mock =
        { practitioners: [{ identifier: [{ system: 'http://hl7.org/fhir/sid/us-npi', value: '1528231610' }] }] }
      practice_name = subject.send(:find_practice_name, mock)
      expect(practice_name).to eq(nil)
    end

    it 'returns the practice name when practice name is given in extension cc location' do
      mock = { extension: { cc_location: { practice_name: 'Practice Name' } } }
      practice_name = subject.send(:find_practice_name, mock)
      expect(practice_name).to eq('Practice Name')
    end

    it 'returns the practice name when practice name is given in practitioners' do
      mock =
        { practitioners: [{ identifier: [{ system: 'http://hl7.org/fhir/sid/us-npi', value: '1528231610' }],
                            practice_name: 'Practice Name' }] }
      practice_name = subject.send(:find_practice_name, mock)
      expect(practice_name).to eq('Practice Name')
    end

    it 'returns the cc location name when cc location name is given in both' do
      mock =
        { practitioners: [{ identifier: [{ system: 'http://hl7.org/fhir/sid/us-npi', value: '1528231610' }],
                            practice_name: 'Practice Name' }],
          extension: { cc_location: { practice_name: 'CC Location Name' } } }
      practice_name = subject.send(:find_practice_name, mock)
      expect(practice_name).to eq('CC Location Name')
    end
  end
end
