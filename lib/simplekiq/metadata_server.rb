require 'sidekiq'
require 'simplekiq/metadata_client'
require 'pry'

module Simplekiq
  class MetadataServer
    def config
      Sidekiq.configure_server do |config|
        config.client_middleware do |chain|
          chain.add(Simplekiq::MetadataClient)
        end
        config.server_middleware do |chain|
          chain.add(Simplekiq::MetadataServer)
        end
      end
    end

    def call(worker, job, queue, *)
      binding.pry
      begin
        record_preexecute(job)
        yield
      rescue e
        record_error(job, e)
      ensure
        record_postexecute(job)
        dispatch_metadata_callback(worker, job, queue)
      end
    end

    def record_preexecute(job)
      binding.pry
      job[:_metadata] |= {}
      job[:_metadata].merge(client_preexecute_metadata(job))
    end

    def record_postexecute(job)
      job[:_metadata] |= {}
      job[:_metadata].merge(client_postexecute_metadata(job))
    end

    def record_error(job, e)
      job[:_metadata][:error] = {
        message: e.message,
        trace: e.backtrace.inspect
      }
    end

    def client_preexecute_metadata(job)
      now = processed_at
      {
        first_processed_at: first_processed_at(job, now),
        processed_at: processed_at,
        processed_by: processed_by,
        processed_by_host: processed_by_host
      }
    end

    def client_postexecute_metadata(job)
      {
        retries: retries(job)
      }
    end

    def first_processed_at(job, processed_at)
      first_processed_at = job[:_metadata][:first_processed_at]
      if first_processed_at.nil? || first_processed_at.empty?
        first_processed_at = processed_at
      end
      first_processed_at
    end

    def processed_at
      Time.now.utc.iso8601
    end

    def processed_by
      @processed_service ||= Chime::Dog.config['app']
    end

    def processed_by_host
      @processed_host ||= Socket.gethostname
    end

    def retries(job)
      return 0 if job[:_metadata][:retries].nil? or job[:_metadata][:retries].empty?

      job[:_metadata][:retries] + 1
    end

    def dispatch_metadata_callback(worker, job, queue)
      nil
    end
  end
end
