require 'spec_helper'
require 'simplekiq/testing'

RSpec.describe Sidekiq::Testing do
  describe '#execute_job' do
    let(:worker) { double(HardWorker) }

    before do
      Sidekiq::Testing.inline!
      class HardWorker
        include Simplekiq::Worker
      end
    end

    it 'calls perform with symbolized keys' do
      expect(worker).to receive(:perform).with({foo: {bar: 'baz'}})

      HardWorker.execute_job(worker, [{'foo' => {'bar' => 'baz' }}])
    end

    it 'ignores extra parameters' do
      expect {
        HardWorker.execute_job(
          worker, [{'foo' => { 'bar' => 'baz' }}, 'bar']
        )
      }.to raise_error(ArgumentError)
    end

    it 'throws an error if a hash is not given' do
      expect {
        HardWorker.execute_job(
          worker, ['foo']
        )
      }.to raise_error(NoMethodError)
    end
  end
end
