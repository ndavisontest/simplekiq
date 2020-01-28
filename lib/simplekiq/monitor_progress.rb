module MonitorProgress
  def perform(args)
    enqueuer_job_id = args.delete(:enqueuer_job_id)
    super(args)
    worker_succeeded!(enqueuer_job_id)
  rescue Exception => _e
    worker_failed!(enqueuer_job_id)
    raise
  end

  private

  def worker_succeeded!(enqueuer_job_id)
    MonitoredJobStatus.worker_successful!(enqueuer_job_id)
  end

  def worker_failed!(enqueuer_job_id)
    MonitoredJobStatus.worker_failed!(enqueuer_job_id)
  end
end
