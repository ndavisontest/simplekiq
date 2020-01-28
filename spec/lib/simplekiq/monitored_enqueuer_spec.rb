require 'spec_helper'
require 'simplekiq/testing'

RSpec.describe Simplekiq::MonitoredEnqueuer do
  let(:worker_instance) { worker_class.new }
  class self::NonMonitoredTestEnqueuer
    include Simplekiq::MonitoredEnqueuer

    sidekiq_options monitoring_enabled: false

    def perform(_args); end
  end

  class self::MonitoredTestEnqueuer
    include Simplekiq::MonitoredEnqueuer

    def perform(_args); end
  end

  describe '#monitoring_enabled?' do
    let(:worker_class) { self.class::MonitoredTestEnqueuer }
    subject(:add_to_thread_context) { worker_instance.send(:monitoring_enabled?) }

    it { is_expected.to be true }

    context 'when overriden in options' do
      let(:worker_class) { self.class::NonMonitoredTestEnqueuer }

      it { is_expected.to be false }
    end
  end

  describe '#add_enqueuer_info_to_thread_context' do
    subject(:add_to_thread_context) { worker_instance.send(:add_enqueuer_info_to_thread_context) }

    context 'when monitoring is disabled' do
      let(:worker_class) { self.class::NonMonitoredTestEnqueuer }

      it 'does not set enqueuer job id' do
        subject
        expect(Thread.current['sidekiq.enqueuer_job_id']).to be_blank
      end

      it 'does not set enqueued jobs count' do
        subject
        expect(Thread.current['sidekiq.enqueued_jobs_count']).to be_blank
      end
    end

    context 'when monitoring is enabled' do
      let(:worker_class) { self.class::MonitoredTestEnqueuer }

      it 'does not set enqueuer job id' do
        subject
        expect(Thread.current['sidekiq.enqueuer_job_id']).to eq worker_instance.jid
      end

      it 'does not set enqueued jobs count' do
        subject
        expect(Thread.current['sidekiq.enqueued_jobs_count']).to be_zero
      end
    end
  end

  describe '#remove_enqueuer_info_from_thread_context' do
    let(:worker_class) { self.class::MonitoredTestEnqueuer }
    subject(:add_to_thread_context) { worker_instance.send(:remove_enqueuer_info_from_thread_context) }

    before do
      Thread.current['sidekiq.enqueuer_job_id'] = 'job_id'
      Thread.current['sidekiq.enqueued_jobs_count'] = 20
      subject
    end

    it 'resets enqueuer job id' do
      expect(Thread.current['sidekiq.enqueuer_job_id']).to be_blank
    end

    it 'resets jobs count' do
      expect(Thread.current['sidekiq.enqueued_jobs_count']).to be_blank
    end
  end

  describe '#perform' do
    subject(:run_worker) do
      Sidekiq::Testing.inline! { worker_class.new.perform(params) }
    end
    let(:params) { { date: Date.today } }
    let(:job_id) { '9d1547c7ac10baa30795787e' }
    let(:worker_class) { self.class::MonitoredTestEnqueuer }
    let(:polling_params) do
      {
        job_class: worker_class.to_s,
        job_id: job_id,
        monitor_timeout: monitor_timeout,
        polling_frequency: polling_frequency,
      }
    end
    let(:job_status_params) do
      {
        job_id: job_id,
        expiry: monitor_timeout,
      }
    end
    let(:monitor_timeout) { MonitoringSetup::DEFAULT_MONITOR_TIMEOUT_IN_SECONDS }
    let(:polling_frequency) { MonitoringSetup::DEFAULT_POLLING_FREQUENCY_IN_SECONDS }

    before do
      allow_any_instance_of(worker_class).to receive(:jid).and_return(job_id)
    end

    it 'initializes job status' do
      expect(MonitoredJobStatus).to receive(:setup_new_job)
        .with(hash_including(job_status_params))
        .and_call_original

      run_worker
    end

    it 'enqueues a polling worker' do
      expect(PollingWorker).to receive(:perform_in)
        .with(MonitoringSetup::DEFAULT_POLLING_FREQUENCY_IN_SECONDS, hash_including(polling_params))
        .and_call_original
      run_worker
    end

    it 'sets thread context' do
      expect_any_instance_of(MonitoringSetup).to receive(:add_enqueuer_info_to_thread_context)
      run_worker
    end

    it 'sets total jobs' do
      expect(MonitoredJobStatus).to receive(:set_total_jobs)
        .with(job_id, 0)
        .and_call_original
      run_worker
    end

    it 'removes thread context when complete' do
      expect_any_instance_of(MonitoringSetup).to receive(:remove_enqueuer_info_from_thread_context)
      run_worker
    end

    context 'when monitoring is disabled' do
      let(:worker_class) { self.class::NonMonitoredTestEnqueuer }

      it 'initializes job status' do
        expect(MonitoredJobStatus).not_to receive(:setup_new_job)
        run_worker
      end

      it 'enqueues a polling worker' do
        expect(PollingWorker).not_to receive(:perform_in)
        run_worker
      end
    end

    context 'when the monitor timeout is overriden' do
      class self::MonitoredTestWithTimeoutEnqueuer
        include Simplekiq::MonitoredEnqueuer

        sidekiq_options monitor_timeout: 100_000, polling_frequency: 600

        def perform(_args); end
      end

      let(:worker_class) { self.class::MonitoredTestWithTimeoutEnqueuer }
      let(:monitor_timeout) { 100_000 }
      let(:polling_frequency) { 600 }

      it 'initializes job status' do
        expect(MonitoredJobStatus).to receive(:setup_new_job)
          .with(hash_including(job_status_params))
          .and_call_original

        run_worker
      end

      it 'enqueues a polling worker' do
        expect(PollingWorker).to receive(:perform_in)
          .with(polling_frequency, hash_including(polling_params))
          .and_call_original
        run_worker
      end
    end
  end
end
