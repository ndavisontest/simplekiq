require 'sidekiq'
require 'simplekiq/metadata'
require 'simplekiq/metadata_client'
require 'simplekiq/metadata_recorder'

module Simplekiq
  class MetadataServer
    include Simplekiq::Metadata
    include Simplekiq::MetadataRecorder

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

    def call(_, job, _, *)
      begin_ref_micros = get_process_time_micros
      begin
        add_metadata_preexecute(job)
        yield
      rescue e
        add_metadata_error(job, e)
      ensure
        add_metadata_postexecute(job, begin_ref_micros)
        record(job)
      end
    end

    def add_metadata_preexecute(job)
      if job[METADATA_KEY].nil?
        job[METADATA_KEY] = {}
      end
      job[METADATA_KEY].merge(server_preexecute_metadata(job))
    end

    def add_metadata_postexecute(job, begin_ref_micros)
      if job[METADATA_KEY].nil?
        job[METADATA_KEY] = {}
      end
      job[METADATA_KEY].merge(server_postexecute_metadata(job, begin_ref_micros))
    end

    def add_metadata_error(job, e)
      # Just overwrite any prior error because this could be memory intensive
      # under a situation with lots of retries
      job[METADATA_KEY]['error'] = {
        message: e.message,
        trace: e.backtrace.inspect
      }
    end

    def server_preexecute_metadata(job)
      now = processed_at
      {
        first_processed_at: first_processed_at(job, now),
        processed_at: processed_at,
        processed_by: processed_by,
        processed_by_host: processed_by_host
      }
    end

    def server_postexecute_metadata(job, begin_ref_micros)
      {
        elapsed_time_ms: elapsed_time_ms(begin_ref_micros),
        retries: retries(job)
      }
    end

    def elapsed_time_ms(begin_ref_micros)
      ((get_process_time_micros - begin_ref_micros) / 1_000).ceil.to_i
    end

    def first_processed_at(job, processed_at)
      first_processed_at = job[METADATA_KEY]['first_processed_at']
      if first_processed_at.nil? || first_processed_at.empty?
        first_processed_at = processed_at
      end
      first_processed_at
    end

    def processed_at
      get_time
    end

    def processed_by
      @processed_service ||= Simplekiq.app_name
    end

    def processed_by_host
      @processed_host ||= Socket.gethostname
    end

    def retries(job)
      retries = job[METADATA_KEY]['retries']
      return 0 if retries.nil? or retries.empty?

      job[METADATA_KEY]['retries'] + 1
    end
  end
end
