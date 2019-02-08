require 'spec_helper'
require 'sidekiq/testing'


RSpec.describe Simplekiq::Worker do

  describe '.get_sidekiq_options' do
    context 'when no options are provided' do
      class NoOptionsDummyWorker
        include Simplekiq::Worker
      end

      it 'has a queue name which matches the worker name' do
        expect(NoOptionsDummyWorker.get_sidekiq_options).to include('queue' => 'nooptionsdummy')
      end
    end

    context 'when no options are provided' do
      class WithOptionsDummyWorker
        include Simplekiq::Worker
        sidekiq_options queue: 'some-queue'
      end

      it 'has a queue name which matches the worker name' do
        expect(WithOptionsDummyWorker.get_sidekiq_options).to include('queue' => 'some-queue')
      end
    end
  end
end
