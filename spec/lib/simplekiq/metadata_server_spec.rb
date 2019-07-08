require 'spec_helper'
require 'simplekiq/testing'

class HardWorker
  include Simplekiq::Worker

  def perform(_)
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
      chain.add(Simplekiq::MetadataServer)
    end
  end

  after do
    Timecop.return
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
        allow_any_instance_of(Simplekiq::MetadataClient).to receive(:request_id).and_return(request_id)
      end

      it 'includes request_id in the following workers metadata' do
        expect{ HardWorker.perform_async({}) }.to change{ Thread.current['atlas.request_id'] }.from(nil).to(request_id)
      end
    end
  end
end
