require 'sidekiq'
require 'simplekiq/metadata'
require 'simplekiq/metadata_recorder'
require 'socket'

module Simplekiq
  class MetadataClient
    include Simplekiq::Metadata
    include Simplekiq::MetadataRecorder

    def call(_worker, job, _queue, *)
      job.merge!(client_metadata)
      yield
    ensure
      record(job)
    end

    def client_metadata
      {
        'enqueued_from' => enqueued_from,
        'enqueued_from_host' => enqueued_from_host,
        'request_id' => request_id
      }
    end

    def request_id
      Thread.current['atlas.request_id'] || Thread.current['core.request_id']
    end

    def enqueued_from
      @enqueued_service ||= Simplekiq.app_name
    end

    def enqueued_from_host
      @enqueued_host ||= Socket.gethostname
    end
  end
end
