require 'spec_helper'
require 'simplekiq/testing'
require 'simplekiq/metadata_recorder'
require 'pry'

RSpec.describe Simplekiq::MetadataClient do
  let(:app) { 'APP' }
  let(:hostname) { 'HOSTNAME' }
  let(:request_id) { 123 }
  let(:recorder) { Simplekiq::MetadataRecorder }

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
      allow(recorder).to receive(:record) do |job|
        expect(job[Simplekiq::Metadata::METADATA_KEY]['request_id']).to eq(request_id)
      end
      HardWorker.perform_async({})
    end
  end
end