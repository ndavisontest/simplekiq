require 'spec_helper'

RSpec.describe Simplekiq::RetryLimit do
  context 'with sidekiq_options' do
    let(:worker) { TacoMakingWorker.new }
    let(:job) { { 'retry' => 100 } }

    context 'when retry option is an integer' do
      before do
        class TacoMakingWorker
          include Simplekiq::Worker
          sidekiq_options retry: 0
        end
      end

      it 'sets the retry key in the job' do
        expect{
          described_class.new.call(worker, job, 'queue')
        }.to change{
          job['retry']
        }.from(100).to(0)
      end
    end

    context 'when retry option is a boolean' do
      before do
        class TacoMakingWorker
          include Simplekiq::Worker
          sidekiq_options retry: false
        end
      end

      it 'sets the retry key in the job' do
        expect{
          described_class.new.call(worker, job, 'queue')
        }.to change{
          job['retry']
        }.from(100).to(false)
      end
    end

    context 'without retry option' do
      before do
        class TacoMakingWorker
          include Simplekiq::Worker
          sidekiq_options foo: :bar
        end
      end

      it 'sets to default retry of true' do
        expect{
          described_class.new.call(worker, job, 'queue')
        }.to change{
          job['retry']
        }.from(100).to(true)
      end
    end
  end

  context 'without sidekiq_options' do
    before do
      class TacoMakingWorker
        include Simplekiq::Worker
      end
    end

    let(:worker) { TacoMakingWorker.new }
    let(:job) { { 'retry' => retry_value } }

    context 'integer retry' do
      let(:retry_value) { 100 }
      it 'does not set the retry key' do
        expect{
          described_class.new.call(worker, job, 'queue')
        }.not_to change{ job['retry'] }
      end
    end

    context 'boolean retry' do
      let(:retry_value) { false }
      it 'does not set the retry key' do
        expect{
          described_class.new.call(worker, job, 'queue')
        }.not_to change{ job['retry'] }
      end
    end
  end
end
