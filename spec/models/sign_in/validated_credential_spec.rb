# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignIn::ValidatedCredential, type: :model do
  let(:validated_credential) do
    create(:validated_credential,
           user_verification:,
           credential_email:,
           client_config:,
           user_attributes:)
  end

  let(:user_verification) { create(:user_verification) }
  let(:credential_email) { 'some-credential-email' }
  let(:client_config) { create(:client_config) }
  let(:user_attributes) do
    { first_name: 'some-first-name',
      last_name: 'some-last-name',
      email: credential_email }
  end

  describe 'validations' do
    describe '#user_verification' do
      subject { validated_credential.user_verification }

      context 'when user_verification is nil' do
        let(:user_verification) { nil }
        let(:expected_error_message) { "Validation failed: User verification can't be blank" }
        let(:expected_error) { ActiveModel::ValidationError }

        it 'raises validation error' do
          expect { subject }.to raise_error(expected_error, expected_error_message)
        end
      end

      context 'when client_config is nil' do
        let(:client_config) { nil }
        let(:expected_error_message) { "Validation failed: Client config can't be blank" }
        let(:expected_error) { ActiveModel::ValidationError }

        it 'raises validation error' do
          expect { subject }.to raise_error(expected_error, expected_error_message)
        end
      end
    end

    describe '#user_attributes' do
      context 'when user_attributes is nil' do
        let(:user_attributes) { nil }
        let(:expected_error_message) { "Validation failed: User verification can't be blank" }
        let(:expected_error) { ActiveModel::ValidationError }

        it 'raises validation error' do
          expect { subject }.to raise_error(expected_error, expected_error_message)
        end
      end
    end
  end
end
