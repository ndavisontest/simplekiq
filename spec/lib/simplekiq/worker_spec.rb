require 'spec_helper'

RSpec.describe Simplekiq::Worker do
  describe '.get_sidekiq_options' do
    context 'when options are provided' do
      before do
        class WithOptionsDummyWorker
          include Simplekiq::Worker
          sidekiq_options queue: 'some_queue'
        end
      end

      it 'has a queue name which matches the worker name' do
        expect(WithOptionsDummyWorker.get_sidekiq_options).to include('queue' => 'some_queue')
      end
    end

    context 'when its a Rails app' do
      let(:rails) { double('Rails') }
      before do
        stub_const('Rails', rails)
        allow(rails).to receive_message_chain(
          'application.class.parent_name.underscore'
        ).and_return('app_name')
      end

      context 'when no options are provided' do
        before do
          class NoOptionsDummyWorker
            include Simplekiq::Worker
          end
        end

        it 'has a queue name which matches the worker name' do
          expect(NoOptionsDummyWorker.get_sidekiq_options).to include('queue' => 'app_name-no_options_dummy')
        end
      end
    end

    context 'namespaced class' do
      context 'when no options are provided' do
        before do
          module Namespaced
            class NoOptionsDummyWorker
              include Simplekiq::Worker
            end
          end
        end

        it 'has a queue name which matches the worker name' do
          expect(Namespaced::NoOptionsDummyWorker.get_sidekiq_options).to include('queue' => 'namespaced_no_options_dummy')
        end
      end
    end

    context 'when its not a Rails app' do
      context 'when no options are provided' do
        before do
          class NoOptionsDummyWorker
            include Simplekiq::Worker
          end
        end

        it 'has a queue name which matches the worker name' do
          expect(NoOptionsDummyWorker.get_sidekiq_options).to include('queue' => 'no_options_dummy')
        end
      end
    end
  end
end
