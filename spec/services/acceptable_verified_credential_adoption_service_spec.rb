# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AcceptableVerifiedCredentialAdoptionService do
  let(:service) { AcceptableVerifiedCredentialAdoptionService.new(user) }
  let(:user) { create(:user, :dslogon) }
  let(:user_verification) { create(:dslogon_user_verification, dslogon_uuid: user.edipi) }
  let!(:user_account) { user_verification.user_account }
  let(:statsd_key) { 'api.user_transition_availability' }
  let(:with_avc) { create(:user_acceptable_verified_credential, :with_avc, user_account:) }
  let(:with_ivc) { create(:user_acceptable_verified_credential, :with_ivc, user_account:) }
  let(:without_avc_or_ivc) { create(:user_acceptable_verified_credential, :without_avc_ivc, user_account:) }

  before { allow(StatsD).to receive(:increment) }

  describe '.perform' do
    context 'User is dslogon authenticated' do
      it 'returns correct credential type - dslogon' do
        expect(service.perform).to include(credential_type: SAML::User::DSLOGON_CSID)
      end

      context 'When user has avc' do
        let!(:user_acceptable_verified_credential) { with_avc }

        it 'reactivation campaign is recommended' do
          expect(service.perform).to include(campaign: 'reactivation')
        end

        it 'logs attempt' do
          service.perform
          expect(StatsD).to have_received(:increment).exactly(1).times
          expect(StatsD).to have_received(:increment)
            .with("#{statsd_key}.reactivation_campaign.dslogon").exactly(1).time
        end
      end

      context 'When user has ivc' do
        let!(:user_acceptable_verified_credential) { with_ivc }

        it 'reactivation campaign is recommended' do
          expect(service.perform).to include(campaign: 'reactivation')
        end

        it 'logs attempt' do
          service.perform
          expect(StatsD).to have_received(:increment).exactly(1).times
          expect(StatsD).to have_received(:increment)
            .with("#{statsd_key}.reactivation_campaign.dslogon").exactly(1).time
        end
      end

      context 'When user has no avc/ivc' do
        let!(:user_acceptable_verified_credential) { without_avc_or_ivc }

        context 'When Flipper organic_conversion_experiment is enabled' do
          it 'organic campaign is recommended' do
            expect(service.perform).to include(campaign: 'organic')
          end

          it 'logs attempt' do
            service.perform
            expect(StatsD).to have_received(:increment).exactly(1).times
            expect(StatsD).to have_received(:increment).with("#{statsd_key}.organic_campaign.dslogon").exactly(1).time
          end
        end

        context 'When Flipper organic_conversion_experiment is disabled' do
          before do
            Flipper.disable(:organic_conversion_experiment)
          end

          it 'no campaign is recommended' do
            expect(service.perform).not_to include(:campaign)
          end

          it 'does not logs attempt' do
            service.perform
            expect(StatsD).to have_received(:increment).exactly(0).times
          end
        end
      end
    end

    context 'When user is login.gov authenticated' do
      let(:user) { create(:user, :accountable_with_logingov_uuid, authn_context: IAL::LOGIN_GOV_IAL2) }
      let(:user_verification) { create(:logingov_user_verification, logingov_uuid: user.logingov_uuid) }
      let!(:user_acceptable_verified_credential) { with_avc }

      it 'returns correct credential type - login.gov' do
        expect(service.perform).to include(credential_type: SAML::User::LOGINGOV_CSID)
      end

      context 'When user has avc' do
        it 'no campaign is recommended' do
          expect(service.perform).not_to include(:campaign)
        end

        it 'does not log attempt' do
          service.perform
          expect(StatsD).to have_received(:increment).exactly(0).times
        end
      end

      context 'When user has ivc' do
        let!(:user_acceptable_verified_credential) { with_ivc }

        it 'no campaign is recommended' do
          expect(service.perform).not_to include(:campaign)
        end

        it 'does not log attempt' do
          service.perform
          expect(StatsD).to have_received(:increment).exactly(0).times
        end
      end

      context 'When user has no avc/ivc' do
        let!(:user_acceptable_verified_credential) { without_avc_or_ivc }

        context 'When Flipper organic_conversion_experiment is enabled' do
          it 'no campaign is recommended' do
            expect(service.perform).not_to include(:campaign)
          end

          it 'logs attempt' do
            service.perform
            expect(StatsD).to have_received(:increment).exactly(0).times
          end
        end

        context 'When Flipper organic_conversion_experiment is disabled' do
          before do
            Flipper.disable(:organic_conversion_experiment)
          end

          it 'no campaign is recommended' do
            expect(service.perform).not_to include(:campaign)
          end

          it 'logs attempt' do
            service.perform
            expect(StatsD).to have_received(:increment).exactly(0).times
          end
        end
      end
    end

    context 'When user is idme authenticated' do
      let(:user) { create(:user, :accountable, authn_context: LOA::IDME_LOA3_VETS) }
      let(:user_verification) { create(:idme_user_verification, idme_uuid: user.idme_uuid) }
      let!(:user_acceptable_verified_credential) { with_avc }

      it 'returns correct credential type - idme' do
        expect(service.perform).to include(credential_type: SAML::User::IDME_CSID)
      end

      context 'When user has avc' do
        it 'no campaign is recommended' do
          expect(service.perform).not_to include(:campaign)
        end

        it 'does not log attempt' do
          service.perform
          expect(StatsD).to have_received(:increment).exactly(0).times
        end
      end

      context 'When user has ivc' do
        let!(:user_acceptable_verified_credential) { with_ivc }

        it 'no campaign is recommended' do
          expect(service.perform).not_to include(:campaign)
        end

        it 'does not log attempt' do
          service.perform
          expect(StatsD).to have_received(:increment).exactly(0).times
        end
      end

      context 'When user has no avc/ivc' do
        let!(:user_acceptable_verified_credential) { without_avc_or_ivc }

        context 'When Flipper organic_conversion_experiment is enabled' do
          it 'no campaign is recommended' do
            expect(service.perform).not_to include(:campaign)
          end

          it 'logs attempt' do
            service.perform
            expect(StatsD).to have_received(:increment).exactly(0).times
          end
        end

        context 'When Flipper organic_conversion_experiment is disabled' do
          before do
            Flipper.disable(:organic_conversion_experiment)
          end

          it 'no campaign is recommended' do
            expect(service.perform).not_to include(:campaign)
          end

          it 'logs attempt' do
            service.perform
            expect(StatsD).to have_received(:increment).exactly(0).times
          end
        end
      end
    end

    context 'When user is mhv authenticated' do
      let(:user) { create(:user, :mhv, authn_context: SAML::User::MHV_ORIGINAL_CSID) }
      let(:user_verification) { create(:mhv_user_verification, mhv_uuid: user.mhv_correlation_id) }
      let!(:user_acceptable_verified_credential) { with_avc }

      it 'returns correct credential type - mhv' do
        expect(service.perform).to include(credential_type: SAML::User::MHV_ORIGINAL_CSID)
      end

      context 'When user has avc' do
        it 'reactivation campaign is recommended' do
          expect(service.perform).to include(campaign: 'reactivation')
        end

        it 'logs attempt' do
          service.perform
          expect(StatsD).to have_received(:increment).exactly(1).times
          expect(StatsD).to have_received(:increment)
            .with("#{statsd_key}.reactivation_campaign.mhv").exactly(1).time
        end
      end

      context 'When user has ivc' do
        let!(:user_acceptable_verified_credential) { with_ivc }

        it 'reactivation campaign is recommended' do
          expect(service.perform).to include(campaign: 'reactivation')
        end

        it 'logs attempt' do
          service.perform
          expect(StatsD).to have_received(:increment).exactly(1).times
          expect(StatsD).to have_received(:increment)
            .with("#{statsd_key}.reactivation_campaign.mhv").exactly(1).time
        end
      end

      context 'When user has no avc/ivc' do
        let!(:user_acceptable_verified_credential) { without_avc_or_ivc }

        context 'When Flipper organic_conversion_experiment is enabled' do
          it 'organic campaign is recommended' do
            expect(service.perform).to include(campaign: 'organic')
          end

          it 'logs attempt' do
            service.perform
            expect(StatsD).to have_received(:increment).exactly(1).times
            expect(StatsD).to have_received(:increment).with("#{statsd_key}.organic_campaign.mhv").exactly(1).time
          end
        end

        context 'When Flipper organic_conversion_experiment is disabled' do
          before do
            Flipper.disable(:organic_conversion_experiment)
          end

          it 'no campaign is recommended' do
            expect(service.perform).not_to include(:campaign)
          end

          it 'does not logs attempt' do
            service.perform
            expect(StatsD).to have_received(:increment).exactly(0).times
          end
        end
      end
    end
  end
end
