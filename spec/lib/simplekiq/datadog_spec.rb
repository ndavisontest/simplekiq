require 'spec_helper'

RSpec.describe Simplekiq::Datadog do
  context 'tags' do
    let(:datadog_middleware) do
      Sidekiq.server_middleware.entries.detect do |entry|
        entry.klass == Sidekiq::Middleware::Server::Datadog
      end
    end

    let(:datadog_args) { datadog_middleware.instance_variable_get(:@args).first }

    subject(:tag) do
      datadog_args[:tags].first.call(nil, nil, nil, nil)
    end

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
