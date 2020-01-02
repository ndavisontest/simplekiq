require 'simplekiq/worker'
require 'simplekiq/monitor_progress'

module Simplekiq
  module MonitoredWorker
    def self.included(base)
      base.include Simplekiq::Worker
      base.prepend MonitorProgress

      base.extend(ClassMethods)
    end

    module ClassMethods
      def perform_async(args)
        setup_monitoring(args)
        super
      end

      def perform_in(interval, args)
        setup_monitoring(args)
        super
      end

      def perform_at(interval, args)
        setup_monitoring(args)
        super
      end

      def setup_monitoring(args)
        increment_job_count
        args[:enqueuer_job_id] = enqueuer_job_id_from_thread
      end

      def increment_job_count
        Thread.current['sidekiq.enqueued_jobs_count'] = Thread.current['sidekiq.enqueued_jobs_count'].to_i + 1
      end

      def enqueuer_job_id_from_thread
        Thread.current['sidekiq.enqueuer_job_id']
      end
    end
  end
end
