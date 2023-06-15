# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LoginAdoptionEmailJob do
  let(:job) { described_class.new(user) }
  let(:reactivation_template) { Settings.vanotify.services.va_gov.template_id.login_reactivation_email }
  let(:user_account) { user_verification.user_account }

  describe '#perform' do
    context 'User is dslogon authenticated' do
      let(:user) { create(:user, :dslogon) }
      let(:user_verification) { create(:dslogon_user_verification, dslogon_uuid: user.edipi) }

      context 'When user has avc' do
        let!(:user_acceptable_verified_credential) do
          create(:user_acceptable_verified_credential, :with_avc, user_account:)
        end

        it 'sends an email' do
          expect(VANotify::EmailJob).to receive(:perform_async).with(
            user.email,
            reactivation_template,
            {}
          )

          job.perform_async
        end
      end

      context 'When user has ivc' do
        let!(:user_acceptable_verified_credential) do
          create(:user_acceptable_verified_credential, :with_ivc, user_account:)
        end

        it 'sends an email' do
          expect(VANotify::EmailJob).to receive(:perform_async).with(
            user.email,
            reactivation_template,
            {}
          )

          job.perform_async
        end
      end

      context 'when user does not have avc/ivc' do
        let!(:user_acceptable_verified_credential) do
          create(:user_acceptable_verified_credential, :without_avc_ivc, user_account:)
        end

        it 'does not send an email' do
          expect(VANotify::EmailJob).not_to receive(:perform_async).with(
            user.email,
            reactivation_template,
            {}
          )

          job.perform_async
        end
      end
    end

    context 'User is mhv authenticated' do
      let(:user) { create(:user, :mhv, authn_context: SAML::User::MHV_ORIGINAL_CSID) }
      let(:user_verification) { create(:mhv_user_verification, mhv_uuid: user.mhv_correlation_id) }

      context 'When user has avc' do
        let!(:user_acceptable_verified_credential) do
          create(:user_acceptable_verified_credential, :with_avc, user_account:)
        end

        it 'sends an email' do
          expect(VANotify::EmailJob).to receive(:perform_async).with(
            user.email,
            reactivation_template,
            {}
          )

          job.perform_async
        end
      end

      context 'When user has ivc' do
        let!(:user_acceptable_verified_credential) do
          create(:user_acceptable_verified_credential, :with_ivc, user_account:)
        end

        it 'sends an email' do
          expect(VANotify::EmailJob).to receive(:perform_async).with(
            user.email,
            reactivation_template,
            {}
          )

          job.perform_async
        end
      end

      context 'when user does not have avc/ivc' do
        let!(:user_acceptable_verified_credential) do
          create(:user_acceptable_verified_credential, :without_avc_ivc, user_account:)
        end

        it 'does not send an email' do
          expect(VANotify::EmailJob).not_to receive(:perform_async).with(
            user.email,
            reactivation_template,
            {}
          )

          job.perform_async
        end
      end
    end

    context 'When user is login.gov authenticated' do
      let(:user) { create(:user, :accountable_with_logingov_uuid, authn_context: IAL::LOGIN_GOV_IAL2) }
      let(:user_verification) { create(:logingov_user_verification, logingov_uuid: user.logingov_uuid) }

      context 'When user has avc' do
        let!(:user_acceptable_verified_credential) do
          create(:user_acceptable_verified_credential, :with_avc, user_account:)
        end

        it 'does not send an email' do
          expect(VANotify::EmailJob).not_to receive(:perform_async).with(
            user.email,
            reactivation_template,
            {}
          )

          job.perform_async
        end
      end

      context 'When user has ivc' do
        let!(:user_acceptable_verified_credential) do
          create(:user_acceptable_verified_credential, :with_ivc, user_account:)
        end

        it 'does not send an email' do
          expect(VANotify::EmailJob).not_to receive(:perform_async).with(
            user.email,
            reactivation_template,
            {}
          )

          job.perform_async
        end
      end

      context 'when user does not have avc/ivc' do
        let!(:user_acceptable_verified_credential) do
          create(:user_acceptable_verified_credential, :without_avc_ivc, user_account:)
        end

        it 'does not send an email' do
          expect(VANotify::EmailJob).not_to receive(:perform_async).with(
            user.email,
            reactivation_template,
            {}
          )

          job.perform_async
        end
      end
    end

    context 'When user is idme authenticated' do
      let(:user) { create(:user, :accountable, authn_context: LOA::IDME_LOA3_VETS) }
      let(:user_verification) { create(:idme_user_verification, idme_uuid: user.idme_uuid) }

      context 'When user has avc' do
        let!(:user_acceptable_verified_credential) do
          create(:user_acceptable_verified_credential, :with_avc, user_account:)
        end

        it 'does not send an email' do
          expect(VANotify::EmailJob).not_to receive(:perform_async).with(
            user.email,
            reactivation_template,
            {}
          )

          job.perform_async
        end
      end

      context 'When user has ivc' do
        let!(:user_acceptable_verified_credential) do
          create(:user_acceptable_verified_credential, :with_ivc, user_account:)
        end

        it 'does not send an email' do
          expect(VANotify::EmailJob).not_to receive(:perform_async).with(
            user.email,
            reactivation_template,
            {}
          )

          job.perform_async
        end
      end

      context 'when user does not have avc/ivc' do
        let!(:user_acceptable_verified_credential) do
          create(:user_acceptable_verified_credential, :without_avc_ivc, user_account:)
        end

        it 'does not send an email' do
          expect(VANotify::EmailJob).not_to receive(:perform_async).with(
            user.email,
            reactivation_template,
            {}
          )

          job.perform_async
        end
      end
    end
  end
end
