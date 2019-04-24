module Chime
  module Simplekiq
    module Middleware
      module MetadataServer
        def call(_worker, job, _queue, *)
          begin
            yield
            record(job)
          end
        end

        def record(job)
          job['_metadata'] = metadata
        end

        def metadata
          {
            enqueued_at: enqueued_at,
            enqueued_from: enqueued_from,
            enqueued_from_host: enqueued_from_host,
            enqueued_from_src_location: src_location,
            request_id: request_id
          }
        end

        def request_id
          nil
        end

        def enqueued_at
          nil
        end

        def enqueued_from
          nil
        end

        def enqueued_from_host
          nil
        end

        def enqueued_from_src_location
          nil
        end
      end
    end
  end
end
