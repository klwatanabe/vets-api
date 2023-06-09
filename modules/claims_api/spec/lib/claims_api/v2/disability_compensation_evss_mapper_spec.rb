# frozen_string_literal: true

require 'rails_helper'
require 'claims_api/v2/disability_compensation_evss_mapper'

describe ClaimsApi::V2::DisabilityCompensationEvssMapper do
  describe '526 claim maps to the evss container' do
    let(:form_data) do
      JSON.parse(
        Rails.root.join(
          'modules',
          'claims_api',
          'spec',
          'fixtures',
          'v2',
          'veterans',
          'disability_compensation',
          'form_526_json_api.json'
        ).read
      )
    end
    let(:auto_claim) do
      create(:auto_established_claim, form_data: form_data['data']['attributes'])
    end
    let(:evss_data) { ClaimsApi::V2::DisabilityCompensationEvssMapper.new(auto_claim).map_claim[:form526] }

    context '526 section 0' do
      it 'maps the cert correctly' do
        expect(evss_data[:claimantCertification]).to be true
      end
    end

    context '526 section 1' do
      it 'maps the mailing address' do
        addr = evss_data[:veteran][:currentMailingAddress]
        expect(addr[:addressLine1]).to eq('1234 Couch Street')
        expect(addr[:city]).to eq('Portland')
        expect(addr[:country]).to eq('USA')
        expect(addr[:zipFirstFive]).to eq('41726')
        expect(addr[:state]).to eq('OR')
      end

      it 'maps the other veteran info' do
        expect(evss_data[:veteran][:fileNumber]).to eq('AB123CDEF')
        expect(evss_data[:veteran][:currentlyVAEmployee]).to eq(false)
        expect(evss_data[:veteran][:emailAddress]).to eq('valid@somedomain.com')
      end
    end

    # context '526 section 2, change of address' do
    #   it 'maps the dates' do
    #     addr = evss_data[:veteran][:changeOfAddress]
    #     expect(addr[:beginningDate]).to eq('2012-11-31')
    #     expect(addr[:endingDate]).to eq('2013-10-11')
    #     expect(addr[:addressChangeType]).to eq('TEMPORARY')
    #     expect(addr[:addressLine1]).to eq('10 Peach St')
    #     expect(addr[:addressLines2]).to eq('Apt 1')
    #     expect(addr[:city]).to eq('Atlanta')
    #     expect(addr[:country]).to eq('USA')
    #     expect(addr[:zipFirstFive]).to eq('42220')
    #     expect(addr[:state]).to eq('GA')
    #   end
    # end

    # TODO: uncomment this when doing https://jira.devops.va.gov/browse/API-27320
    # context '526 section 4, toxic exposure' do
    #   it 'maps the attributes correctly' do
    #     expect(evss_data[:disabilities][0][:specialIssues]).to eq('PACT')
    #   end
    # end

    context '526 section 5, claim info: disabilities' do
      it 'maps the attributes correctly' do
        disability = evss_data[:disabilities][0]
        secondary = disability[:secondaryDisabilities][0]

        expect(disability[:disabilityActionType]).to eq('REOPEN')
        expect(disability[:name]).to eq('PTSD (post traumatic stress disorder)')
        expect(disability[:classificationCode]).to eq('5420')
        expect(disability[:serviceRelevance]).to eq('ABCDEFG')
        expect(disability[:ratedDisabilityId]).to eq('ABCDEFGHIJKLMNOPQRSTUVWX')
        expect(disability[:diagnosticCode]).to eq(0)
        expect(disability[:exposureOrEventOrInjury]).to eq('EXPOSURE')
        expect(disability[:approximateBeginDate]).to eq({ year: 4592, month: 11, day: 4 })

        expect(secondary[:name]).to eq('ABCDEF')
        expect(secondary[:disabilityActionType]).to eq('SECONDARY')
        expect(secondary[:serviceRelevance]).to eq('ABCDEFGHIJKLMNOPQ')
        expect(secondary[:classificationCode]).to eq('ABCDEFGHIJKLMNO')
        expect(secondary[:approximateBeginDate]).to eq({ year: 9904, month: 1, day: 3 })
      end
    end
  end
end
