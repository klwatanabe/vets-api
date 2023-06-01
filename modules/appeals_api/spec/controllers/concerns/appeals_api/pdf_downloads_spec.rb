# frozen_string_literal: true

require 'digest'
require 'rails_helper'
require AppealsApi::Engine.root.join('spec', 'spec_helper.rb')

class ExampleController < ApplicationController
  include AppealsApi::PdfDownloads
end

describe AppealsApi::PdfDownloads do
  include FixtureHelpers

  describe '#watermark' do
    let(:input_pdf_path) { fixture_filepath('pdfs/v3/expected_10182.pdf') }
    let!(:output_pdf_path) { described_class.watermark(input_pdf_path) }

    after do
      # We don't have a way to make assertions about images - only text. The watermark
      # needs to be validated manually by commenting this out and looking at the generated
      # file in the rails tmp folder:
      FileUtils.rm_f(output_pdf_path)
    end

    it 'generates a version of the PDF with text unchanged and the watermark on each page' do
      expect(output_pdf_path).to match_pdf(input_pdf_path)
      expect(Digest::MD5.file(output_pdf_path).hexdigest)
        .not_to eq(Digest::MD5.file(input_pdf_path).hexdigest)
    end
  end

  describe ExampleController do
    let(:appeal) { create(:notice_of_disagreement_v0) }

    describe '#download_authorized?' do
      context 'when request has no X-VA-ICN header' do
        it 'is false' do
          expect(subject.download_authorized?(appeal)).to eq(false)
        end
      end

      context 'when request has X-VA-ICN header' do
        let(:icn) { '1008714701V416111' }
        let(:headers) { { 'X-VA-ICN' => icn } }

        before { headers.each { |k, v| request.headers[k] = v } }

        context "when the request's X-VA-ICN header matches the X-VA-ICN in the appeal's auth_headers" do
          before do
            appeal.auth_headers['X-VA-ICN'] = icn
            appeal.save
          end

          it 'is true' do
            expect(subject.download_authorized?(appeal)).to eq(true)
          end
        end

        context 'when the original appeal has no saved X-VA-ICN in auth_headers but does have a veteran_icn value' do
          context 'when the ICNs match' do
            before { appeal.update!(veteran_icn: icn) }

            it 'is true' do
              expect(subject.download_authorized?(appeal)).to eq(true)
            end
          end

          context "when the ICNs don't match" do
            before { appeal.update!(veteran_icn: '0000000000V000000') }

            it 'is false' do
              expect(subject.download_authorized?(appeal)).to eq(false)
            end
          end
        end

        context 'when the original appeal has no saved ICN information and MPI profile must be looked up' do
          let(:cassette_name) { 'mpi/find_candidate/valid_icn_full' }

          before { VCR.insert_cassette(cassette_name) }
          after { VCR.eject_cassette(cassette_name) }

          context "X-VA-SSN from appeal's auth_headers doesn't match the MPI profile" do
            it 'is false' do
              expect(subject.download_authorized?(appeal)).to eq(false)
            end
          end

          context "X-VA-SSN from appeal's auth_headers matches the MPI profile" do
            before do
              appeal.auth_headers['X-VA-SSN'] = '796122306'
              appeal.save
            end

            it 'is true' do
              expect(subject.download_authorized?(appeal)).to eq(true)
            end
          end
        end
      end
    end
  end
end
