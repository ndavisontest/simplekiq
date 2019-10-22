# frozen_string_literal: true

require 'sidekiq/pro/super_fetch'

module Simplekiq
  # A Sidekiq work fetcher that can rate-limit queues.
  #
  # Install *after* Sidekiq.config.super_fetch! via:
  # require 'simplekiq/throttle_fetch'
  # Sidekiq.options[:fetch] = Simplekiq::ThrottleFetch
  class ThrottleFetch < Sidekiq::Pro::SuperFetch
    CONFIG_KEY = 'simplekiq_throttle_fetch_config'
    EXPIRE_SECONDS = 60 * 60 * 10

    attr_reader :throttle_config

    def initialize(retriever = Sidekiq::Pro::SuperFetch::Retriever.instance, options)
      super(retriever, options)
      Sidekiq.logger.info('ThrottleFetch activated')

      @throttle_config = redis_intmap(CONFIG_KEY)
      Sidekiq.logger.info("Using throttle config: #{throttle_config}")
    end

    # Override: Note the work retrieved by the base class and
    # increment the value in a per-minute, per-queue counter.
    def retrieve_work
      work = super

      current_key = time_sample_key(Time.now)
      if work && throttle_config.key?(work.queue_name)
        Sidekiq.redis do |conn|
          conn.hincrby(current_key, work.queue_name, 1)
          conn.expire(current_key, EXPIRE_SECONDS)
        end
      end

      work
    end

    # Override: Get list of queues, but elide the ones currently over
    # their configured per-minute rate.
    def queues_cmd
      super.reject { |queue| active_throttles.include?(queue) }
    end

    # Return an array of queue names currently above configured limits.
    def active_throttles
      return [] if throttle_config.empty?

      cur = redis_intmap(time_sample_key(Time.now))
      throttle_config
        .keys
        .select { |k| cur.key?(k) && cur[k] > throttle_config[k] }
        .map { |k| "queue:#{k}" }
    end

    def redis_intmap(key)
      Sidekiq
        .redis { |conn| conn.hgetall(key) }
        .reduce({}) { |acc, (k, v)| acc.merge(k => v.to_i) }
    end

    def time_sample_key(time)
      sample_ts = time.strftime('%Y%m%d%H%M')
      "throttle_fetch:#{sample_ts}"
    end
  end
end

# Copied from super-fetch. Shame.
Sidekiq.configure_server do |config|
  config.on(:startup) do
    opts = Sidekiq.options
    if opts[:fetch] == Simplekiq::ThrottleFetch
      s = Sidekiq::Pro::SuperFetch::Retriever.new
      s.listen_for_pauses
      s.start(opts)
      Sidekiq::Pro::SuperFetch::Retriever.instance = s
    end
  end
end
