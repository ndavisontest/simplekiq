require 'spec_helper'
require 'simplekiq/testing'

RSpec.describe Simplekiq::MetadataServer do
  let(:app) { 'APP' }
  let(:hostname) { 'HOSTNAME' }
  let(:request_id) { 123 }
  let(:recorder) { Simplekiq::MetadataRecorder }

  before do
    Thread.current['atlas.request_id'] = request_id
    Sidekiq::Testing.inline!
    Sidekiq::Testing.server_middleware do |chain|
      chain.add(Simplekiq::MetadataClient)
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
      now = Time.now
      Timecop.freeze(now) do
        allow(recorder).to receive(:record) do |job|
          expect(job[Simplekiq::Metadata::METADATA_KEY]['processed_at']).to eq(now)
        end
        HardWorker.perform_async({})
      end
    end
  end
end