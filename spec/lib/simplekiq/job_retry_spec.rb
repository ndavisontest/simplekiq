require 'spec_helper'

RSpec.describe Sidekiq::JobRetry do
  describe '#local' do
    let(:worker) { HardWorker.new }
    let(:handler) { Sidekiq::JobRetry.new }
    let(:job) { { 'class' => 'HardWorker', 'args' => {}, 'retry' => true } }

    before do
      allow_any_instance_of(described_class).to receive(:attempt_retry)
    end

    context 'without retry option set' do
      before do
        class HardWorker
          include Sidekiq::Worker
        end
      end

      it 'sets retry' do
        expect{
          handler.local(worker, job, 'default') do
            raise StandardError
          end
        }.to raise_error(Sidekiq::JobRetry::Skip)

        expect(job['retry']).to eq(true)
      end
    end

    context 'with retry 0' do
      before do
        class HardWorker
          include Sidekiq::Worker
          sidekiq_options retry: 0
        end
      end

      it 'sets retry' do
        expect{
          handler.local(worker, job, 'default') do
            raise StandardError
          end
        }.to raise_error(Sidekiq::JobRetry::Skip)
        expect(job['retry']).to eq(0)
      end
    end

    context 'with retry nil' do
      before do
        class HardWorker
          include Sidekiq::Worker
          sidekiq_options retry: nil
        end
      end

      it 'sets retry' do
        expect{
          handler.local(worker, job, 'default') do
            raise StandardError
          end
        }.to raise_error(Sidekiq::JobRetry::Skip)

        expect(job['retry']).to eq(25)
      end
    end
  end
end
