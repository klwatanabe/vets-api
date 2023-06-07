# frozen_string_literal: true

require 'rails_helper'
require 'bd/bd'

describe ClaimsApi::BD do
  let(:data) do
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
  let(:target_veteran) do
    OpenStruct.new(
      icn: '1013062086V794840',
      first_name: 'abraham',
      last_name: 'lincoln',
      loa: { current: 3, highest: 3 },
      ssn: '796111863',
      edipi: '8040545646',
      participant_id: '600061742',
      mpi: OpenStruct.new(
        icn: '1013062086V794840',
        profile: OpenStruct.new(ssn: '796111863')
      )
    )
  end
  let(:auth_header) {{"Authorization"=>"Bearer token"}}
  let(:token) do
    OpenStruct.new( client_credentials_token?: true, payload: {"scp": []} )
  end
  let(:auto_claim) {
    ClaimsApi::AutoEstablishedClaim.create(
      status: ClaimsApi::AutoEstablishedClaim::PENDING,
      auth_headers: auth_header,
      form_data: data["data"]["attributes"],
      cid: token,
      veteran_icn: target_veteran.mpi.icn
    )
  }
  let(:benefits_doc_api) { ClaimsApi::BD.new }

  context 'send a file' do
    it 'can attach a file to the post' do
      # VCR.use_cassette('bd/documents') do

        benefits_doc_api.documents(auto_claim)
        expect(response.status).eq(200)
      # end
    end
  end
end
