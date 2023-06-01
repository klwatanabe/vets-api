# frozen_string_literal: true

shared_examples 'watermarked pdf download endpoint' do |opts|
  let(:created_at) { Time.current }
  let(:appeal) { create(opts[:factory], created_at:, status: 'pending') }
  let(:uuid) { appeal.id }
  let(:api_segment) { appeal.class.name.demodulize.underscore.dasherize }
  let(:form_number) { described_class::FORM_NUMBER }
  let(:path) { "/services/appeals/#{api_segment}s/v0/forms/#{form_number}/#{uuid}/download" }
  let(:pdf_version) { opts[:pdf_version] || 'v3' }
  let(:headers) { { 'X-VA-ICN' => '0000000000V000000' } }
  let(:download_authorized) { true }
  let(:expunged_attrs) do
    # opts[:expunged_attrs] should be any model attributes required to qualify an appeal record for the PII expunge job
    { status: 'complete' }.merge(opts[:expunged_attrs] || {})
  end

  before do
    # See AppealsApi::PdfDownloads specs for tests of `download_authorized?`
    allow_any_instance_of(AppealsApi::PdfDownloads)
      .to receive(:download_authorized?).and_return(download_authorized)

    with_openid_auth(described_class::OAUTH_SCOPES[:GET]) do |auth_header|
      get(path, headers: headers.merge(auth_header))
    end
  end

  context 'when appeal is not found' do
    let(:uuid) { '11111111-1111-1111-1111-111111111111' }

    it 'returns a 404 error' do
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'without X-VA-ICN header' do
    let(:headers) { {} }

    it 'returns a 422 error' do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context 'when unauthorized' do
    let(:download_authorized) { false }

    it 'returns a 401 error' do
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when appeal is not yet submitted' do
    it 'returns a 422 error' do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context 'when appeal is submitted' do
    let(:appeal) { create(opts[:factory], created_at:, pdf_version:, status: 'submitted') }
    let(:expected_filename) { "#{form_number}-#{api_segment}-#{uuid}.pdf" }

    after { FileUtils.rm_f(expected_filename) }

    it 'returns a PDF' do
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/pdf; charset=utf-8')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include("filename=\"#{expected_filename}\"")
    end
  end

  context 'when PII has been expunged after the expiration period' do
    let(:appeal) do
      Timecop.freeze(1.year.ago) { create(opts[:factory], pdf_version:, **expunged_attrs) }
    end

    it 'returns a 410 error' do
      expect(response).to have_http_status(:gone)
    end
  end
end
