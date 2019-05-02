require 'spec_helper'
require 'simplekiq/testing'
require 'pry'

RSpec.describe Simplekiq::MetadataClient do
  before do
    Sidekiq::Testing.inline!
    class HardWorker
      include Simplekiq::Worker

      def perform(params)
        binding.pry
      end
    end
  end

  describe 'MetadataClient' do
    it 'blah' do
      HardWorker.execute_job(HardWorker.new, [{}])
    end
  end
end