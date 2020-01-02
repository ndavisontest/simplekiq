require 'spec_helper'
require 'simplekiq/testing'

RSpec.describe PollingWorker do
  describe '#perform' do
    subject(:run_worker) do
      Sidekiq::Testing.inline! { described_class.new.perform(params) }
    end
    before do
      class TestEnqueuerWorker
        include Simplekiq::MonitoredEnqueuer

        def on_complete(status:, params:); end
      end
    end
    let(:job_id) { SecureRandom.hex }
    let(:polling_frequency) { 1800 }
    let(:total_jobs) { 100 }
    let(:params) do
      {
        job_id: job_id,
        job_class: 'TestEnqueuerWorker',
        polling_frequency: polling_frequency
      }
    end

    context 'when the job status is empty' do
      it 'does not retry' do
        expect(described_class).not_to receive(:perform_in)
        run_worker
      end
    end

    context 'when the job is expired' do
      before do
        MonitoredJobStatus.setup_new_job(job_id: job_id, expiry: 1)
        MonitoredJobStatus.set_total_jobs(job_id, total_jobs)
        allow_any_instance_of(MonitoredJobStatus).to receive(:expire_at).and_return(Time.now - 10)
      end

      it 'does not retry' do
        expect(described_class).not_to receive(:perform_in)
        run_worker
      end
    end

    context 'when the job is pending' do
      before do
        MonitoredJobStatus.setup_new_job(job_id: job_id, expiry: 10)
        MonitoredJobStatus.set_total_jobs(job_id, total_jobs)

        MonitoredJobStatus.worker_successful!(job_id, total_jobs - 10)
      end

      it 'retries' do
        expect(described_class).to receive(:perform_in)
        run_worker
      end

      it 'increments the number of retries in the params' do
        expect(described_class).to receive(:perform_in).once.with(polling_frequency, hash_including(retry: 1))
        run_worker
      end
    end

    context 'when the job is successful' do
      before do
        MonitoredJobStatus.setup_new_job(job_id: job_id, expiry: 10)
        MonitoredJobStatus.set_total_jobs(job_id, total_jobs)
        MonitoredJobStatus.worker_successful!(job_id, total_jobs)
      end

      it 'does not retry' do
        expect(described_class).not_to receive(:perform_in)
        run_worker
      end

      it 'triggers on_complete callback' do
        expect_any_instance_of(TestEnqueuerWorker).to receive(:on_complete).once.and_call_original
        run_worker
      end

      context 'when callback does not exist' do
        before do
          allow_any_instance_of(TestEnqueuerWorker).to receive(:respond_to?).with(:on_complete).and_return(false)
        end

        it 'does not retry' do
          expect(described_class).not_to receive(:perform_in)
          run_worker
        end

        it 'triggers on_complete callback' do
          expect_any_instance_of(TestEnqueuerWorker).not_to receive(:on_complete)
          run_worker
        end
      end
    end

    context 'when the job is successful' do
      before do
        MonitoredJobStatus.setup_new_job(job_id: job_id, expiry: 10)
        MonitoredJobStatus.set_total_jobs(job_id, total_jobs)
        MonitoredJobStatus.worker_successful!(job_id, total_jobs - 1)
        MonitoredJobStatus.worker_failed!(job_id, 1)
      end

      it 'does not retry' do
        expect(described_class).not_to receive(:perform_in)
        run_worker
      end

      it 'triggers on_complete callback' do
        expect_any_instance_of(TestEnqueuerWorker).to receive(:on_complete).once
        run_worker
      end
    end
  end
end
