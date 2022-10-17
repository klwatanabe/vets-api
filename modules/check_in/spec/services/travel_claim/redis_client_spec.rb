# frozen_string_literal: true

require 'rails_helper'

describe TravelClaim::RedisClient do
  subject { described_class }

  let(:redis_client) { subject.build }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
  let(:redis_token_expiry) { 59.minutes }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)

    Rails.cache.clear
  end

  describe 'attributes' do
    it 'responds to settings' do
      expect(redis_client.respond_to?(:settings)).to be(true)
    end

    it 'gets redis_token_expiry from settings' do
      expect(redis_client.redis_token_expiry).to eq(redis_token_expiry)
    end
  end

  describe '.build' do
    it 'returns an instance of RedisClient' do
      expect(redis_client).to be_an_instance_of(TravelClaim::RedisClient)
    end
  end

  describe '#get' do
    context 'when cache does not exist' do
      it 'returns nil' do
        expect(redis_client.get).to eq(nil)
      end
    end

    context 'when cache exists' do
      before do
        Rails.cache.write(
          'token',
          '12345',
          namespace: 'check-in-btsss-cache',
          expires_in: redis_token_expiry
        )
      end

      it 'returns the cached value' do
        expect(redis_client.get).to eq('12345')
      end
    end

    context 'when cache has expired' do
      before do
        Rails.cache.write(
          'token',
          '67890',
          namespace: 'check-in-btsss-cache',
          expires_in: redis_token_expiry
        )
      end

      it 'returns nil' do
        Timecop.travel(redis_token_expiry.from_now) do
          expect(redis_client.get).to eq(nil)
        end
      end
    end
  end

  describe '#save' do
    let(:token) { '12345' }

    it 'saves the value in cache' do
      expect(redis_client.save(token: token)).to eq(true)

      val = Rails.cache.read(
        'token',
        namespace: 'check-in-btsss-cache'
      )
      expect(val).to eq(token)
    end
  end
end
