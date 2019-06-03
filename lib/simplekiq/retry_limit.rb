module Simplekiq
  class RetryLimit
    def call(worker, job, queue)
      job.merge!(worker.sidekiq_options_hash&.slice('retry') || {})
      yield
    end
  end
end

