require 'spec_helper'
require 'simplekiq/testing'
require 'simplekiq/metadata_recorder'
require 'timecop'
require 'chime-atlas'

RSpec.describe Simplekiq::MetadataClient do
  let(:app) { 'APP' }
  let(:hostname) { 'HOSTNAME' }
  let(:request_id) { 123 }

  before do
    Chime::Atlas::RequestContext.set(request_id: request_id)
    Thread.current['atlas.request_id'] = request_id
    Sidekiq::Testing.inline!
    allow(Socket).to receive(:gethostname).and_return(hostname)
    allow(Simplekiq).to receive(:app_name).and_return(app)

    class HardWorker
      include Simplekiq::Worker

      def perform(_)
      end
    end
  end

  after do
    Chime::Atlas::RequestContext.clear
  end

  it 'includes the request id in metadata' do
    expect_any_instance_of(Simplekiq::MetadataClient).to receive(:record) do |_, job|
      expect(job['request_id']).to eq(request_id)
    end
    HardWorker.perform_async({})
  end

  it 'includes the service enqueueing the job in the metadata' do
    expect_any_instance_of(Simplekiq::MetadataClient).to receive(:record) do |_, job|
      expect(job['enqueued_from']).to eq(app)
    end
    HardWorker.perform_async({})
  end

  it 'includes the host enqueueing the job in the metadata' do
    expect_any_instance_of(Simplekiq::MetadataClient).to receive(:record) do |_, job|
      expect(job['enqueued_from_host']).to eq(hostname)
    end
    HardWorker.perform_async({})
  end
end
