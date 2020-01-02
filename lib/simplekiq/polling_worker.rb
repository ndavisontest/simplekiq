class PollingWorker
  include Simplekiq::Worker

  def perform(params)
    @params = params
    return if expired?

    if job_info.status == :pending
      retry_job!
    else
      send_callback
    end
  end

  private

  def job_id
    @params[:job_id]
  end

  def job_info
    @job_info ||= MonitoredJobStatus.new(job_id)
  end

  def job_instance
    job_class = @params[:job_class]
    Object.const_get(job_class.camelize).new unless job_class.nil?
  end

  def callback?
    job_instance.respond_to?(:on_complete)
  end

  def send_callback
    job_instance.on_complete(**callback_params) if callback?
  end

  def expired?
    job_info.status == :new || Time.now > job_info.expire_at
  end

  def retry_job!
    self.class.perform_in(@params[:polling_frequency], retry_params)
  end

  def retry_params
    @params.merge(retry: @params[:retry].to_i + 1)
  end

  def callback_params
    {
      status: job_info,
      params: @params[:params]
    }
  end
end
