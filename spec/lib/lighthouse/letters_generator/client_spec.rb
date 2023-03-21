# frozen_string_literal true
require 'rails_helper'
require 'lighthouse/letters_generator/client'
require 'lighthouse/letters_generator/service_error'

RSpec.describe Lighthouse::LettersGenerator::Client do
  FAKE_RESPONSES_PATH = 'spec/lib/lighthouse/letters_generator/fakeResponses'
  before do
    @stubs = Faraday::Adapter::Test::Stubs.new
    @conn = Faraday.new { |b| b.adapter(:test, @stubs) }
  end

  context "#get_eligible_letter_types" do
    it 'returns a list of eligible letter types' do
      # Arrange
      fakeResponseJson = File.read("#{FAKE_RESPONSES_PATH}/fakeResponse.json")
      fakeResponseBody = JSON.parse(fakeResponseJson)

      @stubs.get('/eligible-letters?icn=DOLLYPARTON') do
        [ 200, {}, fakeResponseBody ]
      end

      client = Lighthouse::LettersGenerator::Client.new(@conn)

      # Act
      response = client.get_eligible_letter_types('DOLLYPARTON')

      # Assert
      expect(response[:letters][0]).to have_key("letterType")
      expect(response[:letters][0]).to have_key("letterName")
      expect(response).to have_key(:letter_destination)
    end

    context "Error handling" do
      it 'handles an error that returns a detailed response' do
        ## This test covers classes of client errors in lighthouse that 
        ## have a detailed response, exemplified in fakeBadRequest.json.
        ## Status codes include: 400, 404, 406, 433, 500
        ## Link: https://developer.va.gov/explore/verification/docs/va_letter_generator

        fakeResponseJson = File.read("#{FAKE_RESPONSES_PATH}/fakeBadRequest.json")
        fakeResponseBody = JSON.parse(fakeResponseJson)
        @stubs.get('/eligible-letters?icn=BADREQUEST') do
          raise Faraday::BadRequestError.new("YIKES", fakeResponseBody)
        end

        client = Lighthouse::LettersGenerator::Client.new(@conn)

        expect {client.get_eligible_letter_types('BADREQUEST')}.to raise_error do |error|
          expect(error).to be_an_instance_of(Lighthouse::LettersGenerator::ServiceError)
          expect(error.status).to be(fakeResponseBody['status'])
          expect(error.message).to be(fakeResponseBody['detail'])
        end
      end

      it 'handles an error that returns a simplified response' do
        ## This test covers classes of client errors in lighthouse that 
        ## have a detailed response, exemplified in fakeBadRequest.json.
        ## Status codes include: 401, 403, 413, 429
        ## Link: https://developer.va.gov/explore/verification/docs/va_letter_generator

        fakeResponseJson = File.read("#{FAKE_RESPONSES_PATH}/fakeUnauthorized.json")
        fakeResponseBody = JSON.parse(fakeResponseJson)
        @stubs.get('/eligible-letters?icn=BadActor') do
          raise Faraday::UnauthorizedError.new("don't go in there", fakeResponseBody)
        end

        client = Lighthouse::LettersGenerator::Client.new(@conn)

        expect {client.get_eligible_letter_types('BadActor')}.to raise_error do |error|
          expect(error).to be_an_instance_of(Lighthouse::LettersGenerator::ServiceError)
          expect(error.title).to eq("Faraday::UnauthorizedError")
        end
      end
    end
  end

  context "#get_benefit_information" do
    it 'returns a list of benefit information' do
      # Arrange
      fakeResponseJson = File.read("#{FAKE_RESPONSES_PATH}/fakeResponse.json")
      fakeResponseBody = JSON.parse(fakeResponseJson)

      @stubs.get('/eligible-letters?icn=DOLLYPARTON') do
        [ 200, {}, fakeResponseBody ]
      end

      client = Lighthouse::LettersGenerator::Client.new(@conn)

      # Act
      response = client.get_benefit_information('DOLLYPARTON')

      # Assert
      expect(response).to have_key(:benefitInformation)
      expect(response[:benefitInformation]).not_to be(nil)
    end

  end

  context "#download_letter" do
    it 'returns a letter pdf without letter options' do
      # Arrange
      fakeResponseJson = File.read("#{FAKE_RESPONSES_PATH}/fakeResponse.json")
      fakeResponseBody = JSON.parse(fakeResponseJson)

      @stubs.get('/letters/BENEFIT_SUMMARY/letter?icn=DOLLYPARTON') do
        [ 200, {}, fakeResponseBody ]
      end

      # Act
      client = Lighthouse::LettersGenerator::Client.new(@conn)
      response = client.download_letter('DOLLYPARTON', 'BENEFIT_SUMMARY')

      # Assert
      @stubs.verify_stubbed_calls
      expect(response).not_to be_nil
    end

    it 'returns a letter pdf with letter options' do
      # Arrange
      fakeResponseJson = File.read("#{FAKE_RESPONSES_PATH}/fakeResponse.json")
      fakeResponseBody = JSON.parse(fakeResponseJson)

      @stubs.get('/letters/BENEFIT_SUMMARY/letter?icn=DOLLYPARTON?serviceConnectedDisabilities=true&chapter35Eligibility=true') do
        [ 200, {}, fakeResponseBody ]
      end

      letter_options = fakeResponseBody["benefitInformation"]

      # Act
      client = Lighthouse::LettersGenerator::Client.new(@conn)
      response = client.download_letter('DOLLYPARTON', 'BENEFIT_SUMMARY', letter_options)

      # Assert
      @stubs.verify_stubbed_calls
      expect(response).not_to be(nil)
    end

    context "error handling" do
      it 'returns a 400 if the letter type is not valid' do
        # Arrange
        fakeResponseJson = File.read("#{FAKE_RESPONSES_PATH}/fakeResponse.json")
        fakeResponseBody = JSON.parse(fakeResponseJson)

        @stubs.get('/letters/LETTER_TO_GRANDMA/letter?icn=DOLLYPARTON') do
          [ 200, {}, fakeResponseBody ]
        end

        client = Lighthouse::LettersGenerator::Client.new(@conn)
        
        # Assert
        expect { client.download_letter('DOLLYPARTON', 'LETTER_TO_GRANDMA')}.to raise_error do |error|
          expect(error).to be_an_instance_of(Lighthouse::LettersGenerator::ServiceError)
          expect(error.status).to eq(400)
        end
      end

      it 'handles an error returned from Lighthouse' do
        fakeResponseJson = File.read("#{FAKE_RESPONSES_PATH}/fakeBadRequest.json")
        fakeResponseBody = JSON.parse(fakeResponseJson)
        @stubs.get('/letters/BENEFITS_SUMMARY/letter?icn=BADREQUEST') do
          raise Faraday::BadRequestError.new("YIKES", fakeResponseBody)
        end

        client = Lighthouse::LettersGenerator::Client.new(@conn)

        expect {client.download_letter('BADREQUEST', 'BENEFITS_SUMMARY')}.to raise_error do |error|
          expect(error).to be_an_instance_of(Lighthouse::LettersGenerator::ServiceError)
        end
      end
    end
  end
end
