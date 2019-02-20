require 'spec_helper'

RSpec.describe Sidekiq::Processor do
  describe '#execute_job' do
    let(:worker) { double('Worker', perform: true) }
    let(:manager) { double('Manager', options: {queues: ['default']}) }

    it 'calls perform with symbolized keys' do
      expect(worker).to receive(:perform).with(foo: { bar: 'baz' })

      described_class.new(manager).execute_job(
        worker, [{'foo' => { 'bar' => 'baz' }}]
      )
    end

    it 'ignores extra parameters' do
      expect {
        described_class.new(manager).execute_job(
          worker, [{'foo' => { 'bar' => 'baz' }}, 'bar']
        )
      }.to raise_error(ArgumentError)
    end

    it 'throws an error if a hash is not given' do
      expect {
        described_class.new(manager).execute_job(
          worker, ['foo']
        )
      }.to raise_error(NoMethodError)
    end
  end
end
