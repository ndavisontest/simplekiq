require 'sidekiq'
require 'simplekiq/metadata'
require 'simplekiq/metadata_recorder'
require 'socket'
require 'time'

module Simplekiq
  class MetadataClient
    include Simplekiq::Metadata
    include Simplekiq::MetadataRecorder

    def config
      Sidekiq.configure_client do |config|
        config.client_middleware do |chain|
          chain.add(Simplekiq::MetadataClient)
        end
      end
    end

    def call(_worker, job, _queue, *)
      begin
        add_metadata(job)
        yield
      ensure
        record(job)
      end
    end

    def add_metadata(job)
      job[METADATA_KEY] = client_metadata
    end

    def client_metadata
      {
        enqueued_at: enqueued_at,
        enqueued_from: enqueued_from,
        enqueued_from_host: enqueued_from_host,
        request_id: request_id
      }
    end

    def request_id
      rid = Thread.current['atlas.request_id']
      return rid unless rid.nil?
      Thread.current['core.request_id']
    end

    def enqueued_at
      get_time
    end

    def enqueued_from
      @enqueued_service ||= Simplekiq.app_name
    end

    def enqueued_from_host
      @enqueued_host ||= Socket.gethostname
    end
  end
end
