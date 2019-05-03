require 'spec_helper'
require 'simplekiq/testing'
require 'pry'

RSpec.describe Simplekiq::MetadataServer do
  before do
    Thread.current['atlas.request_id'] = 123
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
    it 'blah' do
      HardWorker.perform_async({})
    end
  end
end