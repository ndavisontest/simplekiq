RSpec.describe Simplekiq do
  it "has a version number" do
    expect(Simplekiq::VERSION).not_to be nil
  end

  describe '#app_name' do
    it { expect(described_class.app_name).to eq(nil) }

    context 'when rails defined' do
      let(:rails) { class_double('Rails') }

      before do
        stub_const('Rails', rails)
      end

      context 'with Rails 6' do
        before do
          stub_const('Rails::VERSION::MAJOR', 6)

          allow(rails).to receive_message_chain(
            'application.class.module_parent_name.underscore'
          ).and_return('app_name')
        end

        it 'overrides default queue' do
          expect(described_class.app_name).to eq('app_name')
        end
      end

      context 'with Rails 5' do
        before do
          stub_const('Rails::VERSION::MAJOR', 5)

          allow(rails).to receive_message_chain(
            'application.class.parent_name.underscore'
          ).and_return('app_name')
        end

        it 'overrides default queue' do
          expect(described_class.app_name).to eq('app_name')
        end
      end
    end
  end

  describe '#enqueue_with_routing' do
    subject { described_class.enqueue_with_routing(params) }

    let(:params) { { queue_name: 'magic-super-queue', class_name: 'MyClassName', params: {} } }

    it 'calls ' do
      expect(Simplekiq::EnqueueRouter.instance).to receive(:enqueue_with_routing).with(params).once

      subject
    end
  end
end
