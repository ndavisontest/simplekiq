# frozen_string_literal: true

module Simplekiq
  # Class to help route sidekiq jobs to the appropriate sidekiq instance if environment variables
  # exist following the convention SIDEKIQ_<service name>_REDIS_URL
  class EnqueueRouter
    include Singleton

    # Enqueue a Sidekiq job into redis, to be picked up by a worker in another app
    def enqueue(queue_name:, class_name:, params:, timestamp: nil)
      push_params = {
        queue: queue_name,
        class: class_name,
        args: [params] # args must be an array
      }
      push_params[:at] = timestamp.to_f if timestamp.present?

      service = queue_name.split('-').first
      alt_redis = redis_for_service(service)

      if defined?(::Chime::Dog)
        Chime::Dog.increment('sidekiq.remote_enqueue', tags: { destination: service })
      end

      Sidekiq::Client.via(alt_redis) { Sidekiq::Client.push(push_params.stringify_keys) }
    end

    def redis_for_service(service)
      @sidekiq_instances[service] || Sidekiq.redis_pool
    end

    def add_pool(service, url)
      if defined?(::Rails)
        Rails.logger.info { "Adding Sidekiq Redis pool for #{service} at #{url}" }
      end
      @sidekiq_instances[service] = ConnectionPool.new { Redis.new(url: url) }
    end

    def reset!
      @sidekiq_instances = {}
      read_instances_from_environment
    end

    def matching_envs
      ENV.each_with_object({}) do |(key, url), hash|
        key.match(/^SIDEKIQ_(.+)_REDIS_URL$/) do |match|
          service_name = match[1].downcase
          hash[service_name] = url
        end
      end
    end

    private

    def read_instances_from_environment
      matching_envs.each do |service_name, url|
        add_pool(service_name, url)
      end
    end

    def initialize
      super()
      reset!
    end
  end
end
