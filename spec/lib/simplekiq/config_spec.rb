require 'spec_helper'

RSpec.describe Simplekiq::Config do
  describe '#config' do
    before do
      allow(Sidekiq.options).to receive(:[]).and_call_original
      allow(Sidekiq.options).to receive(:[]).with(:queues).and_return(['default'])
      allow(Simplekiq::QueueGetter).to receive(:queues).and_return(['queue'])
    end

    it 'sets Sidekiq options' do
      expect{
        Sidekiq.options[:lifecycle_events][:startup].first.call
      }.to change{
        Sidekiq.options[:queues]
      }.from(['default']).to(['queue'])
    end
  end
end
