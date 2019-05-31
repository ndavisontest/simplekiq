require 'spec_helper'

RSpec.describe Simplekiq::QueueGetter do
  describe '.queues' do
    context 'with simplekiq worker' do
      before do
        class HardWorker
          include Simplekiq::Worker
        end
      end

      it 'overrides default queue' do
        expect(described_class.queues).to eq(['hard'])
      end

      context 'when queue overridden' do
        before do
          class HardWorker
            include Simplekiq::Worker
            sidekiq_options queue: 'some-queue'
          end
        end

        it 'respects the override' do
          expect(described_class.queues).to eq(['some-queue'])
        end
      end

      context 'when queue overridden' do
        before do
          class HardWorker
            include Simplekiq::Worker
            sidekiq_options priority: 2
          end
        end

        it 'respects the override' do
          expect(described_class.queues).to eq(['hard', 'hard'])
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
          expect(described_class.queues).to eq(['app_name-hard'])
        end

        context 'when queue overridden' do
          before do
            class HardWorker
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
        allow(HardWorker).to receive(:included_modules).and_return(
          [Sidekiq::Worker]
        )
      end

      it 'returns nothing' do
        expect(described_class.queues).to eq([])
      end
    end

    context 'when config file queues' do
      before do
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(nil).and_return('')
        allow(ERB).to receive(:read).and_return(double(result: ''))
        allow(YAML).to receive(:load).and_return(double('[]' => ['queue']))
      end

      it 'raises error' do
        expect{ described_class.queues }.to raise_error('Workers declared in config_file')
      end
    end
  end
end
