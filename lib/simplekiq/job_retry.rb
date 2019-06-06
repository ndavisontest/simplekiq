require 'sidekiq/job_retry'

module Sidekiq
  class JobRetry
    def local(worker, msg, queue)
      yield
    rescue Skip => ex
      raise ex
    rescue Sidekiq::Shutdown => ey
      # ignore, will be pushed back onto queue during hard_shutdown
      raise ey
    rescue Exception => e
      # ignore, will be pushed back onto queue during hard_shutdown
      raise Sidekiq::Shutdown if exception_caused_by_shutdown?(e)

      # OVERRIDE
      # if msg['retry'] == nil
      #   msg['retry'] = worker.class.get_sidekiq_options['retry']
      # end
      msg['retry'] = worker.class.get_sidekiq_options['retry'] || @max_retries

      raise e unless msg['retry']
      attempt_retry(worker, msg, queue, e)
      # We've handled this error associated with this job, don't
      # need to handle it at the global level
      raise Skip
    end
  end
end
