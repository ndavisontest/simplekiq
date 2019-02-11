require 'pry'
RSpec.describe Simplekiq do
  it "has a version number" do
    expect(Simplekiq::VERSION).not_to be nil
  end

  describe '#app_name' do
    it { expect(described_class.app_name).to eq(nil) }

    context 'when rails defined' do
      let(:rails) { double('Rails') }
      before do
        stub_const('Rails', rails)
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
