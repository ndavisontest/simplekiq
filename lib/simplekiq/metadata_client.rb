require 'sidekiq'

module MetadataClient
  def config
    Sidekiq.configure_server do |config|
      config.client_middleware do |chain|
        chain.add(MetadataClient)
      end
    end
  end

  def call(worker, job, queue, *)
    begin
      record_preexecute(job)
      yield
    rescue e
      record_exception(job, e)
    ensure
      record_postexecute(job)
      dispatch_metadata_callback(worker, job, queue)
    end
  end

  def record_preexecute(job)
    job['_metadata'] |= {}
    job['_metadata'].merge(client_preexecute_metadata(job))
  end

  def record_postexecute(job)
    job['_metadata'] |= {}
    job['_metadata'].merge(client_postexecute_metadata(job))
  end

  def record_exception(job, e)
    nil
  end

  def client_preexecute_metadata(job)
    {
      first_processed_at: first_processed_at(job),
      processed_at: processed_at,
      processed_by: processed_by,
      processed_by_host: processed_by_host
    }
  end

  def client_postexecute_metadata(job)
    {
      retries: retries
    }
  end

  def first_processed_at(job)
    nil
  end

  def processed_at
    nil
  end

  def processed_by
    nil
  end

  def processed_by_host
    nil
  end

  def retries
    nil
  end

  def dispatch_metadata_callback(worker, job, queue)
    nil
  end
end
