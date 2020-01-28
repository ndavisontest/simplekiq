require 'simplekiq/monitored_job_status'
require 'simplekiq/polling_worker'

module MonitoringSetup
  DEFAULT_MONITOR_TIMEOUT_IN_SECONDS = 86_400 # 1 day
  DEFAULT_POLLING_FREQUENCY_IN_SECONDS = 900 # 15 minutes

  def perform(*args)
    add_enqueuer_info_to_thread_context
    initialize_status

    super

    set_total_jobs
    setup_monitoring_worker(args)
  ensure
    remove_enqueuer_info_from_thread_context
  end

  def add_enqueuer_info_to_thread_context
    return unless monitoring_enabled?

    Thread.current['sidekiq.enqueuer_job_id'] = jid
    Thread.current['sidekiq.enqueued_jobs_count'] = 0
  end

  def remove_enqueuer_info_from_thread_context
    Thread.current['sidekiq.enqueuer_job_id'] = nil
    Thread.current['sidekiq.enqueued_jobs_count'] = nil
  end

  def monitoring_enabled?
    self.class.get_sidekiq_options['monitoring_enabled']
  end

  def setup_monitoring_worker(args)
    return unless monitoring_enabled?

    monitoring_options = default_monitoring_options.merge(
      job_id: jid,
      job_class: self.class.to_s,
      params: args
    )
    PollingWorker.perform_in(polling_frequency, monitoring_options)
  end

  def initialize_status
    return unless monitoring_enabled?

    MonitoredJobStatus.setup_new_job(
      job_id: jid,
      expiry: monitor_timeout,
    )
  end

  def set_total_jobs
    return unless monitoring_enabled?

    MonitoredJobStatus.set_total_jobs(
      jid,
      Thread.current['sidekiq.enqueued_jobs_count']
    )
  end

  def monitor_timeout
    self.class.get_sidekiq_options['monitor_timeout'] || DEFAULT_MONITOR_TIMEOUT_IN_SECONDS
  end

  def polling_frequency
    self.class.get_sidekiq_options['polling_frequency'] || DEFAULT_POLLING_FREQUENCY_IN_SECONDS
  end

  def default_monitoring_options
    {
      monitor_timeout: monitor_timeout.to_i,
      polling_frequency: polling_frequency.to_i
    }
  end
end
