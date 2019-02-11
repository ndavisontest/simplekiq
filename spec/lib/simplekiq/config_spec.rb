require 'spec_helper'

RSpec.describe Simplekiq::Config do
  describe '#config' do
    before do
      allow(Simplekiq::QueueGetter).to receive(:queues).and_return(['queue'])
    end

    it 'sets Sidekiq options' do
      expect{
        Sidekiq.options[:lifecycle_events][:startup].first.call
      }.to change{
        Sidekiq.options[:queues]
      }.from([]).to(['queue'])
    end
  end
end
