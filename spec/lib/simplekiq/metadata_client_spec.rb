require 'spec_helper'
require 'simplekiq/testing'
require 'simplekiq/metadata_recorder'
require 'timecop'

RSpec.describe Simplekiq::MetadataClient do
  let(:app) { 'APP' }
  let(:hostname) { 'HOSTNAME' }
  let(:request_id) { 123 }

  before do
    Thread.current['atlas.request_id'] = request_id
    Sidekiq::Testing.inline!
    Sidekiq::Testing.server_middleware do |chain|
      chain.add(Simplekiq::MetadataClient)
    end
    allow(Socket).to receive(:gethostname).and_return(hostname)
    allow(Simplekiq).to receive(:app_name).and_return(app)

    class HardWorker
      include Simplekiq::Worker

      def perform(_)
      end
    end
  end

  describe 'MetadataClient' do
    it 'includes the request id in metadata' do
      expect_any_instance_of(Simplekiq::MetadataClient).to receive(:record) do |_, job|
        expect(job[Simplekiq::Metadata::METADATA_KEY][:request_id]).to eq(request_id)
      end
      HardWorker.perform_async({})
    end

    it 'includes the service enqueueing the job in the metadata' do
      expect_any_instance_of(Simplekiq::MetadataClient).to receive(:record) do |_, job|
        expect(job[Simplekiq::Metadata::METADATA_KEY][:enqueued_from]).to eq(app)
      end
      HardWorker.perform_async({})
    end

    it 'includes the host enqueueing the job in the metadata' do
      expect_any_instance_of(Simplekiq::MetadataClient).to receive(:record) do |_, job|
        expect(job[Simplekiq::Metadata::METADATA_KEY][:enqueued_from_host]).to eq(hostname)
      end
      HardWorker.perform_async({})
    end

    it 'includes the time enqueueing the job in the metadata' do
      now = Time.now.utc.round(10).iso8601(3)
      Timecop.freeze(now) do
        expect_any_instance_of(Simplekiq::MetadataClient).to receive(:record) do |_, job|
          expect(job[Simplekiq::Metadata::METADATA_KEY][:enqueued_at]).to eq(now)
        end
        HardWorker.perform_async({})
      end
    end

    context 'Hardworker enqueues another worker' do
      before do
        class SubHardWorker
          include Simplekiq::Worker

          def perform(params)
            puts params
          end
        end

        class HardWorkerDos
          include Simplekiq::Worker

          def perform(_)
            SubHardWorker.perform_async({})
          end
        end

        class ThreadClearingMiddleware
          def call(_worker, job, _queue, *)
            Thread.current['atlas.request_id'] = nil
            yield
          end
        end

        Sidekiq::Testing.server_middleware do |chain|
          chain.add(Simplekiq::MetadataClient)
          chain.add(ThreadClearingMiddleware)
        end
      end

      def assert_request_id(job)
        expect(job[Simplekiq::Metadata::METADATA_KEY][:request_id]).to eq(request_id)
      end

      it 'includes request_id in the following workers metadata' do
        allow_any_instance_of(Simplekiq::MetadataClient)
          .to receive(:record).with(hash_including('class' => 'HardWorkerDos')) {|_, _, job| assert_request_id(job) }
        allow_any_instance_of(Simplekiq::MetadataClient)
          .to receive(:record).with(hash_including('class' => 'SubHardWorker')) {|_,_, job| assert_request_id(job) }
        expect_any_instance_of(Simplekiq::MetadataClient).to receive(:record).twice

        HardWorkerDos.perform_async({})
      end
    end
  end
end
