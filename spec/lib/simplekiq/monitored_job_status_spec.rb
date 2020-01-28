require 'spec_helper'

RSpec.describe MonitoredJobStatus do
  let(:expiry_time) { (Time.now + expiry).iso8601 }
  let(:expiry) { 60 }
  let(:job_id) { SecureRandom.hex }
  let(:total_jobs) { 100 }
  let(:job_status) { MonitoredJobStatus.new(job_id) }
  let(:params) { { job_id: job_id, expiry: expiry } }
  let(:start_time) { Time.now.iso8601 }

  describe '.setup_new_job' do
    subject { described_class.setup_new_job(params) }

    it 'initializes job status' do
      subject
      expect(job_status).not_to be_nil
    end

    it 'sets job start time' do
      subject
      expect(job_status.start_at).to eq start_time
    end

    it 'sets job status expiry time' do
      subject
      expect(job_status.expire_at).to eq expiry_time
    end
  end

  describe '.worker_successful!' do
    subject { described_class.worker_successful!(job_id) }
    let(:successful_jobs) { rand(total_jobs) }

    context 'when the job status has not been initialized' do
      subject { described_class.worker_successful!(job_id, successful_jobs) }

      it 'sets successful count' do
        subject
        expect(job_status.successful).to eq successful_jobs
      end
    end

    context 'when the job status has been initialized' do
      before do
        described_class.setup_new_job(params)
        described_class.worker_successful!(job_id, successful_jobs)
      end

      it 'increments the successful count' do
        subject
        expect(job_status.successful).to eq successful_jobs + 1
      end
    end
  end

  describe '.worker_failed!' do
    subject { described_class.worker_failed!(job_id) }
    let(:failed_jobs) { rand(total_jobs) }

    context 'when the job status has not been initialized' do
      subject { described_class.worker_failed!(job_id, failed_jobs) }

      it 'sets failed count' do
        subject
        expect(job_status.failed).to eq failed_jobs
      end
    end

    context 'when the job status has been initialized' do
      before do
        described_class.setup_new_job(params)
        described_class.worker_failed!(job_id, failed_jobs)
      end

      it 'increments the failed count' do
        subject
        expect(job_status.failed).to eq failed_jobs + 1
      end
    end
  end

  describe '.data_key!' do
    subject { described_class.data_key(job_id) }

    it { is_expected.to eq "job-status-#{job_id}" }
  end

  describe '.set_total_jobs' do
    subject { described_class.set_total_jobs(job_id, total_jobs) }

    context 'when the job status has not been initialized' do
      it 'sets total count' do
        subject
        expect(job_status.total).to eq total_jobs
      end
    end

    context 'when the job status has been initialized' do
      before do
        described_class.setup_new_job(params)
      end

      it 'sets the total count' do
        subject
        expect(job_status.total).to eq total_jobs
      end
    end

    context 'when the total is already set' do
      before do
        described_class.setup_new_job(params)
        described_class.set_total_jobs(job_id, 0)
      end

      it 'sets the total count' do
        subject
        expect(job_status.total).to eq total_jobs
      end
    end
  end

  describe '.initialize' do
    subject(:job_status) { MonitoredJobStatus.new(job_id) }

    context 'when the job was not setup' do
      let(:job_id) { 'random-job' }

      it 'is new' do
        expect(job_status.status).to eq :new
      end

      it 'does not have a start time' do
        expect(job_status.start_at).to be_nil
      end

      it 'does not have an expiry time' do
        expect(job_status.expire_at).to be_nil
      end
    end

    context 'when the job was setup' do
      before do
        described_class.setup_new_job(params)
        described_class.set_total_jobs(job_id, total_jobs)
      end

      it 'has a total jobs' do
        expect(job_status.status).to eq :pending
      end

      it 'sets total jobs' do
        expect(job_status.total).to eq 100
      end
    end

    context 'when the job was setup but not finished' do
      before do
        described_class.setup_new_job(params)
        described_class.set_total_jobs(job_id, total_jobs)
        described_class.worker_successful!(job_id, 64)
      end

      it 'is pending' do
        expect(job_status.status).to eq :pending
      end

      it 'sets a start time' do
        expect(job_status.start_at).to eq start_time
      end

      it 'sets an expiry time' do
        expect(job_status.expire_at).to eq expiry_time
      end
    end

    context 'when the job was setup and some jobs failed' do
      before do
        described_class.setup_new_job(params)
        described_class.set_total_jobs(job_id, total_jobs)
        described_class.worker_successful!(job_id, 91)
        described_class.worker_failed!(job_id, 9)
      end

      it 'is complete' do
        expect(job_status.status).to eq :complete
      end
    end

    context 'when the job was setup and all jobs succeed' do
      before do
        described_class.setup_new_job(params)
        described_class.set_total_jobs(job_id, total_jobs)
        described_class.worker_successful!(job_id, total_jobs)
      end

      it 'is successful' do
        expect(job_status.status).to eq :successful
      end
    end
  end
end
