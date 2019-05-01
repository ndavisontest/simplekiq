require 'chime_atlas'
require 'sidekiq'
require 'socket'
require 'time'

module Simplekiq
  class MetadataServer
    def config
      Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.add(MetadataServer)
        end
      end
    end

    def call(_worker, job, _queue, *)
      begin
        record(job)
        yield
      end
    end

    def record(job)
      job['_metadata'] = server_metadata
    end

    def server_metadata
      {
        enqueued_at: enqueued_at,
        enqueued_from: enqueued_from,
        enqueued_from_host: enqueued_from_host,
        enqueued_from_src_location: src_location,
        request_id: request_id
      }
    end

    def request_id
      Chime::Atlas.request_id
    end

    def enqueued_at
      Time.now.utc.iso8601
    end

    def enqueued_from
      nil
    end

    def enqueued_from_host
      @host ||= Socket.gethostname
    end

    def enqueued_from_src_location
      nil
    end
  end
end
