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
      datadog_args[:tags].first.call(nil,nil,nil,nil)
    end

    it{ expect(subject).to eq('service:undefined') }

    context 'when Rails application' do
      let(:rails) { double('Rails') }
      before do
        stub_const('Rails', rails)
        allow(rails).to receive_message_chain(
          'application.class.parent_name.underscore'
        ).and_return('app_name')
      end

      it{ expect(subject).to eq('service:app_name') }
    end
  end
end
