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
        expect(described_class.queues).to include('hard')
      end

      context 'when strict is true' do
        before do
          Sidekiq.options[:strict] = true
        end

        it 'sets strict option to false' do
          expect{
            described_class.queues
          }.to change{
            Sidekiq.options[:strict]
          }.from(true).to(false)
        end
      end

      context 'when queue overridden' do
        before do
          class HardWorker
            include Simplekiq::Worker
            sidekiq_options queue: 'some-queue'
          end
        end

        it 'respects the override' do
          expect(described_class.queues).to include('some-queue')
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
          expect(described_class.queues).to include('hard', 'hard')
        end
      end

      context 'when it is disabled from SIMPLEKIQ_SKIP_QUEUES' do
        before do
          class HardWorker
            include Simplekiq::Worker
          end
        end

        it 'respects the override' do
          allow(ENV).to receive(:fetch).with('SIMPLEKIQ_SKIP_QUEUES', '').and_return('hard')
          expect(described_class.queues).not_to include('hard')
        end
      end

      context 'when rails defined' do
        let(:rails) { class_double('Rails') }
        before do
          stub_const('Rails', rails)
          stub_const('Rails::VERSION::MAJOR', 6)
          allow(rails).to receive_message_chain(
            'application.class.module_parent_name.underscore'
          ).and_return('app_name')
        end

        it 'overrides default queue' do
          expect(described_class.queues).to include('app_name-hard')
        end

        context 'when queue overridden' do
          before do
            class HardWorker
              include Simplekiq::Worker
              sidekiq_options queue: 'some-queue'
            end
          end

          it 'respects the override' do
            expect(described_class.queues).to include('some-queue')
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

      it 'does not return the queue' do
        expect(described_class.queues).not_to include('hard')
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
