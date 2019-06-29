require 'spec_helper'
require 'simplekiq/testing'
require 'timecop'

RSpec.describe Simplekiq::MetadataServer do
  let(:app) { 'APP' }
  let(:hostname) { 'HOSTNAME' }
  let(:request_id) { 123 }
  let(:recorder) { Simplekiq::MetadataRecorder }

  before do
    Thread.current['atlas.request_id'] = request_id
    Sidekiq::Testing.inline!
    Sidekiq::Testing.server_middleware do |chain|
      chain.add(Simplekiq::MetadataServer)
    end
    class HardWorker
      include Simplekiq::Worker

      def perform(_)
      end
    end
  end

  describe 'MetadataServer' do
    it 'includes the time the job started to process in the metadata' do
      Timecop.freeze do
        now = Simplekiq::MetadataServer.new.get_time
        expect_any_instance_of(Simplekiq::MetadataServer).to receive(:record) do |_, job|
          expect(job['processed_at']).to eq(now)
        end
        HardWorker.perform_async({})
      end
    end

    context 'Hardworker enqueues another worker' do
      before do
        Sidekiq::Testing.server_middleware do |chain|
          chain.add(Simplekiq::MetadataServer)
        end
      end

      it 'includes request_id in the following workers metadata' do
        allow_any_instance_of(Simplekiq::MetadataServer)
          .to receive(:add_request_id_to_thread).and_call_original
        HardWorker.perform_async({})
      end
    end
  end
end
