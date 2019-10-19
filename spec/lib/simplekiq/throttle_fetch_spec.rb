# frozen_string_literal: true

require 'spec_helper'
require 'simplekiq/throttle_fetch'

RSpec.describe Simplekiq::ThrottleFetch do
  subject { described_class.new(queues: %w[a b c]) }

  describe '.redis_intmap' do
    let(:redis_key) { 'somekey' }
    let(:redis_response) { { 'queue' => '47' } }
    let(:return_value) { { 'queue' => 47 } }

    it 'converts redis strings to ints' do
      expect_any_instance_of(Redis).to receive(:hgetall).with(redis_key).and_return(redis_response)

      expect(described_class.redis_intmap(redis_key)).to eq(return_value)
    end
  end

  describe '.time_sample_key' do
    it 'has minute resolution' do
      ts = Time.new(2019, 10, 14, 9, 3, 42)
      expect(described_class.time_sample_key(ts)).to eq('throttle_fetch:201910140903')
    end
  end

end
