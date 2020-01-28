require 'spec_helper'
require 'simplekiq/testing'

RSpec.describe Simplekiq::MonitoredWorker do
  class self::MonitoredTestWorker
    include Simplekiq::MonitoredWorker

    def perform(args)
      check_args(args)
    end

    def check_args(args); end
  end

  let(:fake_params) { { id: 1 } }
  let(:job_count) { 100 }
  let(:job_id) { SecureRandom.hex }
  let(:monitoring_params) { { enqueuer_job_id: job_id } }
  let(:worker_class) { self.class::MonitoredTestWorker }

  before do
    Thread.current['sidekiq.enqueuer_job_id'] = job_id
    Thread.current['sidekiq.enqueued_jobs_count'] = 100
  end

  shared_examples 'adds enqueuer job id to sidekiq and increments job count' do
    it 'adds enqueuer job id to params' do
      expect_any_instance_of(MonitorProgress)
        .to receive(:perform).with(fake_params.merge(monitoring_params))
      subject
    end

    it 'increments the enqueued jobs count' do
      subject
      expect(Thread.current['sidekiq.enqueued_jobs_count']).to eq 101
    end
  end

  describe '.perform_async' do
    subject(:async_perform) do
      Sidekiq::Testing.inline! { worker_class.perform_async(fake_params) }
    end

    include_examples 'adds enqueuer job id to sidekiq and increments job count'
  end

  describe '.perform_in' do
    subject(:perform_in) do
      Sidekiq::Testing.inline! { worker_class.perform_in(10, fake_params) }
    end

    include_examples 'adds enqueuer job id to sidekiq and increments job count'
  end

  describe '.perform_at' do
    subject(:perform_at) do
      Sidekiq::Testing.inline! { worker_class.perform_at(Time.now, fake_params) }
    end

    include_examples 'adds enqueuer job id to sidekiq and increments job count'
  end

  describe '#perform' do
    let(:monitoring_params) { { enqueuer_job_id: job_id } }

    subject(:run_worker) do
      Sidekiq::Testing.inline! { worker_class.new.perform(fake_params.merge(monitoring_params)) }
    end

    it 'removes enqueueing job params before job is performed' do
      expect_any_instance_of(worker_class).to receive(:check_args).with(fake_params)
      run_worker
    end

    it 'marks job as successful' do
      expect(MonitoredJobStatus).to receive(:worker_successful!).with(job_id)
      run_worker
    end

    context 'when the job fails' do
      before do
        expect_any_instance_of(worker_class).to receive(:check_args).and_raise
      end

      it 'marks job as failed' do
        expect(MonitoredJobStatus).to receive(:worker_failed!).with(job_id)
        expect { run_worker }.to raise_error
      end
    end
  end
end
