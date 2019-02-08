require 'spec_helper'

RSpec.describe Simplekiq::Worker do
  let(:rails) { double('Rails') }
  before do
    stub_const('Rails', rails)
    allow(rails).to receive_message_chain(
      'application.class.parent_name.downcase'
    ).and_return('app_name')
  end

  describe '.get_sidekiq_options' do
    context 'when no options are provided' do
      before do
        class NoOptionsDummyWorker
          include Simplekiq::Worker
        end
      end

      it 'has a queue name which matches the worker name' do
        expect(NoOptionsDummyWorker.get_sidekiq_options).to include('queue' => 'app_name-NoOptionsDummy')
      end
    end

    context 'when no options are provided' do
      before do
        class WithOptionsDummyWorker
          include Simplekiq::Worker
          sidekiq_options queue: 'some-queue'
        end
      end

      it 'has a queue name which matches the worker name' do
        expect(WithOptionsDummyWorker.get_sidekiq_options).to include('queue' => 'some-queue')
      end
    end
  end
end
