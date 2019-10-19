# frozen_string_literal: true

require 'sidekiq/fetch'

module Simplekiq
  # A Sidekiq work fetcher that can rate-limit queues.
  class ThrottleFetch < Sidekiq::BasicFetch
    # TODO: What is Sidekiq::Pro:BasicFetch is around?
    CONFIG_KEY = 'simplekiq_throttle_fetch_config'
    EXPIRE_SECONDS = 60 * 60 * 10

    attr_reader :throttle_config

    def initialize(options)
      super(options)

      @throttle_config = redis_intmap(CONFIG_KEY)
    end

    # Override: Note the work retrieved by the base class and
    # increment the value in a per-minute, per-queue counter.
    def retrieve_work
      work = super
      if work && throttle_config.key?(work.queue_name)
        current_key = time_sample_key(Time.now)
        Sidekiq.redis do |conn|
          conn.hincr(current_key, work.queue_name)
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
      throttle_config.keys.select { |k| cur.key?(k) && cur[k] > throttle_config[k] }
    end

    def self.redis_intmap(key)
      Sidekiq
        .redis { |conn| conn.hgetall(key) }
        .reduce({}) { |acc, (k, v)| acc.merge(k => v.to_i) }
    end

    def self.time_sample_key(time)
      sample_ts = time.strftime('%Y%m%d%H%M')
      "throttle_fetch:#{sample_ts}"
    end
  end
end
