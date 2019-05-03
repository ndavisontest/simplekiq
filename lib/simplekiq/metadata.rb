module Simplekiq
  module Metadata
    METADATA_KEY = 'metadata'.freeze

    def get_process_time_micros
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1_000_000).to_i
    end

    def get_time
      Time.now.utc.round(10).iso8601(3)
    end
  end
end