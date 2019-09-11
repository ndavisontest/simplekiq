require 'spec_helper'
require 'sidekiq/testing'

class HardWorker
  include Simplekiq::Worker

  def perform(_)
  end
end

class ThreadCleaner
  def call(_worker, _job, _queue, *)
    Chime::Atlas::RequestContext.clear
    yield
  end
end

RSpec.describe Simplekiq::MetadataServer do
  let(:app) { 'APP' }
  let(:hostname) { 'HOSTNAME' }
  let(:request_id) { 123 }
  let(:recorder) { Simplekiq::MetadataRecorder }
  let(:now) { Simplekiq::MetadataServer.new.get_time }

  before do
    Timecop.freeze
    Sidekiq::Testing.inline!
    Sidekiq::Testing.server_middleware do |chain|
      chain.add(ThreadCleaner)
      chain.add(Simplekiq::MetadataServer)
    end
  end

  after do
    Timecop.return
    Chime::Atlas::RequestContext.clear
  end

  describe 'MetadataServer' do
    it 'includes the time the job started to process in the metadata' do
      expect_any_instance_of(Simplekiq::MetadataServer).to receive(:record).with(
        hash_including(
          'first_processed_at' => now,
          'processed_at' => now,
          'processed_by' => Simplekiq.app_name,
          'processed_by_host' => Socket.gethostname
        )
      )

      HardWorker.perform_async({})
    end

    context 'with request_id' do
      before do
        Chime::Atlas::RequestContext.set(request_id: request_id)
      end

      it 'includes request_id in the following workers metadata' do
        expect_any_instance_of(ThreadCleaner).to receive(:call) do |_, _, job|
          expect(job['request_id']).to eq(request_id)
        end.and_call_original

        expect_any_instance_of(Simplekiq::MetadataServer).to receive(:call) do |_|
          expect(Chime::Atlas::RequestContext.current.to_h[:request_id]).to be_nil
        end.and_call_original

        HardWorker.perform_async({})

        expect(Chime::Atlas::RequestContext.current.to_h[:request_id]).to eq(request_id)
      end
    end

    context 'when a job has request id' do
      it 'adds it to the thread' do
        job = { 'request_id' => request_id }
        Simplekiq::MetadataServer.new.call(nil, job, nil) { HardWorker.perform_async({}) }
        expect(Chime::Atlas::RequestContext.current.to_h[:request_id]).to eq(request_id)
      end
    end
  end
end
