class MonitoredJobStatus
  DEFAULT_EXPIRY_DURATION = 86_400

  attr_reader :job_id, :failed, :total, :successful, :start_at, :expire_at

  def self.setup_new_job(job_id:, expiry: DEFAULT_EXPIRY_DURATION)
    attributes = {
      start_at: Time.now.utc.iso8601,
      expire_at: (Time.now.utc + expiry).iso8601
    }

    redis do |connection|
      connection.hmset(data_key(job_id), *attributes)
      connection.expire(data_key(job_id), expiry)
    end
  end

  def self.set_total_jobs(job_id, total_jobs)
    redis do |connection|
      connection.hmset(data_key(job_id), 'total', total_jobs)
    end
  end

  def self.worker_successful!(job_id, count = 1)
    redis do |connection|
      connection.hincrby(data_key(job_id), 'successful', count)
    end
  end

  def self.worker_failed!(job_id, count = 1)
    redis do |connection|
      connection.hincrby(data_key(job_id), 'failed', count)
    end
  end

  def self.data_key(job_id)
    "job-status-#{job_id}"
  end

  def initialize(job_id)
    @job_id = job_id

    load_status(job_data_from_redis)
  end

  def pending
    pending = total - successful - failed
    [pending, 0].max
  end

  def status
    return :new unless start_at

    if pending.positive?
      :pending
    elsif pending.zero? && failed.positive?
      :complete
    else
      :successful
    end
  end

  def load_status(job_data)
    @start_at = Time.parse(job_data['start_at']) if job_data['start_at']
    @expire_at = Time.parse(job_data['expire_at']) if job_data['expire_at']
    @total = job_data['total'].to_i
    @failed = job_data['failed'].to_i
    @successful = job_data['successful'].to_i
  end

  def job_data_from_redis
    self.class.redis { |connection| connection.hgetall(self.class.data_key(job_id)) }
  end

  def self.redis(&block)
    Sidekiq.redis(&block)
  end
end
