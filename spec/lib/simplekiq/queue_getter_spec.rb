require 'spec_helper'

RSpec.describe Simplekiq::QueueGetter do
  describe '.queues' do
    context 'with simplekiq worker' do
      before do
        class TacoMakingWorker
          include Simplekiq::Worker
        end
      end

      it 'overrides default queue' do
        expect(described_class.queues).to eq(['taco_making'])
      end

      context 'when queue overridden' do
        before do
          class TacoMakingWorker
            include Simplekiq::Worker
            sidekiq_options queue: 'some-queue'
          end
        end

        it 'respects the override' do
          expect(described_class.queues).to eq(['some-queue'])
        end
      end

      context 'when rails defined' do
        let(:rails) { double('Rails') }
        before do
          stub_const('Rails', rails)
          allow(rails).to receive_message_chain(
            'application.class.parent_name.underscore'
          ).and_return('app_name')
        end

        it 'overrides default queue' do
          expect(described_class.queues).to eq(['app_name-taco_making'])
        end

        context 'when queue overridden' do
          before do
            class TacoMakingWorker
              include Simplekiq::Worker
              sidekiq_options queue: 'some-queue'
            end
          end

          it 'respects the override' do
            expect(described_class.queues).to eq(['some-queue'])
          end
        end
      end
    end

    context 'sidekiq worker' do
      before do
        allow(TacoMakingWorker).to receive(:included_modules).and_return(
          [Sidekiq::Worker]
        )
      end

      it 'returns nothing' do
        expect(described_class.queues).to eq([])
      end
    end
  end
end
