# frozen_string_literal: true

require 'simplekiq/enqueue_router'

RSpec.describe Simplekiq::EnqueueRouter do
  let(:class_name) { 'ClassyClassWorker' }
  let(:queue_name) { "#{service_name}-classy_class" }
  let(:service_name) { 'something' }
  let(:timestamp) { nil }
  let(:args) do
    [
      {
        key_1: 'val_1',
        key_2: 'val_2'
      }
    ]
  end
  let(:second_redis_url) { 'redis://fancy.redis.biz' }
  let(:instance) { described_class.instance }

  before do
    instance.reset!
  end

  describe '#enqueue' do
    subject(:enqueue) { instance.enqueue(params) }

    let(:params) do
      {
        class_name: class_name,
        queue_name: queue_name,
        params: args,
      }
    end

    before do
      allow(Sidekiq::Client).to receive(:via).and_call_original
      allow(Sidekiq::Client).to receive(:push)
    end

    it 'calls through redis_pool' do
      enqueue
      expect(Sidekiq::Client).to have_received(:via).with(Sidekiq.redis_pool)
    end

    it 'calls Sidekiq::Client.push with basic args' do
      enqueue
      expect(Sidekiq::Client).to have_received(:push).with(
        'queue' => queue_name,
        'class' => class_name,
        'args' => [args]
      )
    end

    context 'when queue has routing' do
      around do |example|
        ClimateControl.modify(SIDEKIQ_SOMETHING_REDIS_URL: second_redis_url) do
          example.run
        end
      end

      it 'calls through custom redis url' do
        enqueue
        expect(Sidekiq::Client).to have_received(:via)
        expect(Sidekiq::Client).not_to have_received(:via).with(Sidekiq.redis_pool)
      end

      it 'calls Sidekiq::Client.push with basic args' do
        enqueue
        expect(Sidekiq::Client).to have_received(:push).with(
          'queue' => queue_name,
          'class' => class_name,
          'args' => [args]
        )
      end
    end

    context 'when Chime::Dog is defined' do
      let(:chime_dog) { double('Chime::Dog', increment: nil) }

      before do
        stub_const('::Chime::Dog', chime_dog)
      end

      it 'tells DataDog what it did' do
        enqueue
        expect(chime_dog)
          .to have_received(:increment)
          .with('sidekiq.remote_enqueue', tags: { destination: service_name })
      end
    end

    context 'when a timestamp is provided' do
      let(:timestamp) { Time.now.next_day(10).to_time }
      let(:params) { super().merge(timestamp: timestamp) }

      it 'adds the timestamp to the args' do
        expect(Sidekiq::Client).to receive(:push).with(
          'queue' => queue_name,
          'class' => class_name,
          'args' => [args],
          'at' => timestamp.to_f
        )

        enqueue
      end
    end
  end

  describe '.redis_for_service' do
    subject { instance.redis_for_service(service_name) }

    context 'without alternate URL' do
      it 'returns Sidekiq.redis_pool by default' do
        is_expected.to be(Sidekiq.redis_pool)
      end
    end

    context 'with alternate URL' do
      before { instance.add_pool(service_name, second_redis_url) }

      it 'generates a distinct pool' do
        is_expected.not_to be(Sidekiq.redis_pool)
      end

      it 'retains the original for other services' do
        expect(instance.redis_for_service('consumer')).to be(Sidekiq.redis_pool)
      end
    end
  end

  describe '.matching_envs' do
    subject(:matching_envs) { instance.matching_envs }

    around do |example|
      ClimateControl.modify(FOO: 'bar', SIDEKIQ_FUNKY_REDIS_URL: second_redis_url) do
        example.run
      end
    end

    it 'includes the funky redis URL' do
      is_expected.to include('funky' => second_redis_url)
    end

    it 'only yields once' do
      expect(matching_envs.size).to eq(1)
    end
  end
end
