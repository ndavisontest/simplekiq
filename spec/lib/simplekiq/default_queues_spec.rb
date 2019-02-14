require 'spec_helper'

RSpec.describe Simplekiq::DefaultQueues do
  describe '.queues' do
    context 'when rails is not defined' do
      it 'returns an empty array' do
        expect(described_class.queues).to eq([])
      end
    end

    context 'when rails is defined' do
      let(:rails) { double('Rails') }
      before do
        stub_const('Rails', rails)
        allow(rails).to receive_message_chain(
          'application.class.parent_name.underscore'
        ).and_return('app_name')
      end

      it 'returns project-default queues' do
        expect(described_class.queues).to match_array(
          ['app_name-low'] * described_class::LOW_PRIORITY +
          ['app_name-medium'] * described_class::MEDIUM_PRIORITY +
          ['app_name-high'] * described_class::HIGH_PRIORITY +
          ['app_name-critical'] * described_class::CRITICAL_PRIORITY
        )
      end
    end
  end
end
