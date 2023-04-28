require 'rails_helper'
require 'evss/disability_compensation_auth_headers' # required to build a Form526Submission

RSpec.configure do |config|
  config.use_transactional_fixtures = false
end

describe 'Generate Claim' do
  let(:user) { FactoryBot.create(:user, :loa3) }
  let(:auth_headers) do
    EVSS::DisabilityCompensationAuthHeaders.new(user).add_headers(EVSS::AuthHeaders.new(user).to_h)
  end
  let(:evss_claim_id) { rand(100_000_000..999_999_999) }
  let(:saved_claim) { FactoryBot.create(:va526ez) }
  let(:form_json) do
    # Pick other files in this dir (or make your own, for different states/attributes/values of the claim)
    File.read('spec/support/disability_compensation_form/submissions/with_4142.json')
  end
  let(:submission) do
    Form526Submission.create(user_uuid: user.uuid,
                             auth_headers_json: auth_headers.to_json,
                             saved_claim_id: saved_claim.id,
                             form_json:,
                             submitted_claim_id: evss_claim_id)
  end

  it 'creates it...' do
    puts "Created Submission with ID: #{submission.id}"
  end
end
