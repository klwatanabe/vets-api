# frozen_string_literal: true

require 'ostruct'
require 'rails_helper'
require 'lighthouse/direct_deposit/error_parser'

describe Lighthouse::DirectDeposit::ErrorParser do
  include SchemaMatchers

  it 'parses Invalid token error' do
    response = OpenStruct.new(body: { 'error' => 'Invalid token.' })

    e = Lighthouse::DirectDeposit::ErrorParser.parse(response)
    match(e, 'cnp.payment.invalid.token')
  end

  it 'parses Person for ICN not found error' do
    response = OpenStruct.new(body: { 'detail' => 'No data found for ICN' })

    e = Lighthouse::DirectDeposit::ErrorParser.parse(response)
    match(e, 'cnp.payment.icn.not.found')
  end

  it 'parses Invalid ICN error' do
    response = OpenStruct.new(body: { 'detail' => 'getDirectDeposit.icn size' })

    e = Lighthouse::DirectDeposit::ErrorParser.parse(response)
    match(e, 'cnp.payment.icn.invalid')
  end

  it 'parses payment restriction indicators' do
    response = OpenStruct.new(
      body: {
        'error_codes' => [
          {
            'error_code' => 'payment.restriction.indicators.present',
            'detail' => 'hasNoBdnPayments is false.'
          }
        ]
      }
    )

    e = Lighthouse::DirectDeposit::ErrorParser.parse(response)
    match(e, 'cnp.payment.restriction.indicators.present')
  end

  it 'parses a 400 Potential fraud error' do
    response = OpenStruct.new(
      body: {
        'detail' => 'No changes were made. Routing number related to potential fraud.',
      }
    )

    e = Lighthouse::DirectDeposit::ErrorParser.parse(response)
    match(e, 'cnp.payment.routing.number.fraud')
  end

  it 'parses a 429 API rate limit exceeded' do
    response = OpenStruct.new(body: { 'message' => 'API rate limit exceeded' })

    e = Lighthouse::DirectDeposit::ErrorParser.parse(response)
    match(e, 'cnp.payment.api.rate.limit.exceeded')
  end

  private

  def match(error_response, expected_code)
    code = error_response.errors.first[:code]
    expect(code).to eq(expected_code)
  end
end
