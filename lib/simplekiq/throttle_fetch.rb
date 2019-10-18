# frozen_string_literal: true

require 'sidekiq/fetch'

module Simplekiq
  # A Sidekiq work fetcher that can rate-limit queues.
  class ThrottleFetch < Sidekiq::BasicFetch
    THROTTLE_CONFIG_KEY = 'throttle_fetch_config'

    # Override: Note the work retrieved by the base class and
    # increment the value in a per-minute, per-queue counter.
    def retrieve_work
      work = super
      if work && throttle_config.key?(work.queue_name)
        # TODO Set these keys to expire in 4 hours to prevent unbounded growth.
        Sidekiq.redis { |conn| conn.incr(time_sample_key(work.queue_name)) }
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

      cur = current_throttle_rates
      conf = throttle_config

      conf.keys.select { |k| cur.key?(k) && cur[k] > conf[k] }
    end

    # Return a hash
    def current_throttle_rates
      now_ts = Time.now
      counter_keys = throttle_queues.map { |queue| time_sample_key(queue, now_ts) }
      counter_rates = Sidekiq.redis { |conn| conn.mget(counter_keys) }.map(&:to_i)

      # Build hash of results, recovering the queue name from the end
      # of the time_sample_key()-created redis location.
      counter_keys
        .map { |k| k.split(':').last }
        .zip(counter_rates)
        .to_h
    end

    def throttle_queues
      throttle_config.keys
    end

    # Redis-backed throttle config: map of queue names to their per-minute max.
    # TODO: Memoize?
    def throttle_config
      Sidekiq
        .redis { |conn| conn.hgetall(THROTTLE_CONFIG_KEY) }
        .transform_values(&:to_i)
    end

    def self.time_sample_key(queue, time = Time.now)
      sample_ts = time.strftime('%Y%m%d%H%M')
      "tfetch:#{sample_ts}:#{queue}"
    end
  end
end
