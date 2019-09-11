require 'sidekiq'
require 'simplekiq/metadata'
require 'simplekiq/metadata_recorder'
require 'socket'
require 'chime-atlas'

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
      Chime::Atlas::RequestContext.current.to_h.stringify_keys.merge(
        'enqueued_from' => enqueued_from,
        'enqueued_from_host' => enqueued_from_host
      )
    end

    def enqueued_from
      @enqueued_service ||= Simplekiq.app_name
    end

    def enqueued_from_host
      @enqueued_host ||= Socket.gethostname
    end
  end
end
