require 'spec_helper'

RSpec.describe Simplekiq::Datadog do
  context 'tags' do
    subject(:tag) do
      datadog_args[:tags][tag_number].call(nil, nil, nil, nil)
    end
    let(:tag_number) { 0 }
    let(:datadog_middleware) do
      Sidekiq.server_middleware.entries.detect do |entry|
        entry.klass == Sidekiq::Middleware::Server::Datadog
      end
    end

    let(:datadog_args) do
      datadog_middleware.instance_variable_get(:@args).first
    end
    context 'when checking first tag' do
      it { expect(subject).to eq('service:undefined') }

      context 'when Rails application' do
        let(:rails) { class_double('Rails') }
        before do
          stub_const('Rails', rails)
          stub_const('Rails::VERSION::MAJOR', 6)
          allow(rails).to receive_message_chain(
            'application.class.module_parent_name.underscore'
          ).and_return('app_name')
        end

        it { expect(subject).to eq('service:app_name') }
      end
    end
    context 'when checking second tag' do
      let(:tag_number) { 1 }

      context 'when DATADOG_SIDEKIQ_WORKER_GROUP env variable not set' do
        it { expect(subject).to eq('worker_group:undefined') }
      end

      context 'when DATADOG_SIDEKIQ_WORKER_GROUP env variable set' do
        before do
          stub_const(
            'ENV',
            ENV.to_hash.merge(
              'DATADOG_SIDEKIQ_WORKER_GROUP' => 'custom_worker_group'
            )
          )
        end
        it { expect(subject).to eq('worker_group:custom_worker_group') }
      end
    end
  end

  context 'sidekiq pro' do
    # This is a horrible thing to do, but since we don't want to make
    # sidekiq pro a requirement, we get to do this.
    module Kernel
      alias old_require require
      def require(path)
        paths_to_skip = ['sidekiq/middleware/server/statsd'].freeze
        old_require(path) unless paths_to_skip.include?(path)
      end
    end

    let(:sidekiq_pro) { double }
    let(:statsd) { double }

    before do
      stub_const('Sidekiq::Pro', sidekiq_pro)
      stub_const('Sidekiq::Middleware::Server::Statsd', statsd)
    end

    it 'sets Sidekiq::Pro dogstatsd' do
      expect(sidekiq_pro).to receive(:dogstatsd=)

      Simplekiq::Datadog.config
    end
  end
end
