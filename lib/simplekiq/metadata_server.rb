require 'sidekiq'
require 'simplekiq/metadata'
require 'simplekiq/metadata_client'
require 'simplekiq/metadata_recorder'
require 'chime-atlas'

module Simplekiq
  class MetadataServer
    include Simplekiq::Metadata
    include Simplekiq::MetadataRecorder

    def call(_worker, job, _queue, *)
      begin_ref_micros = get_process_time_micros
      begin
        job.merge!(server_preexecute_metadata(job))
        apply_metadata_to_thread(job)
        yield
      ensure
        job.merge!(server_postexecute_metadata(begin_ref_micros))
        record(job)
      end
    end

    def server_preexecute_metadata(job)
      now = processed_at
      {
        'first_processed_at' => first_processed_at(job, now),
        'processed_at' => processed_at,
        'processed_by' => processed_by,
        'processed_by_host' => processed_by_host
      }
    end

    def server_postexecute_metadata(begin_ref_micros)
      { 'elapsed_time_ms' => elapsed_time_ms(begin_ref_micros) }
    end

    def elapsed_time_ms(begin_ref_micros)
      ((get_process_time_micros - begin_ref_micros) / 1_000).ceil.to_i
    end

    def first_processed_at(job, processed_at)
      first_processed_at = job['first_processed_at']
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

    def apply_metadata_to_thread(job)
      metadata = job.symbolize_keys.slice(:request_id, :trace_id, :sampling_priority)

      # In the event the current job enqueues other jobs it will use the same request_id
      Chime::Atlas::RequestContext.set(metadata)
    end
  end
end
