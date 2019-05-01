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
      @enqueued_service ||= Chime::Dog.config['app']
    end

    def enqueued_from_host
      @enqueued_host ||= Socket.gethostname
    end

    def enqueued_from_src_location
      last_stack_is_simplekiq = false
      caller.inspect.reverse_each do |callstack_line|
        entry = split_stackline(callstack_line)
        if is_simplekiq_callstack?(entry)
          last_stack_is_simplekiq = true
        else
          if last_stack_is_simplekiq
            return callstack_entry_hash(entry)
          end
          last_stack_is_simplekiq = false
        end
      end

      callstack_entry_hash([nil, nil, nil])
    end

    private

    def is_simplekiq_callstack?(callstack_entry)
      callstack_entry.first.include?('simplekiq') || callstack_entry.first.include?('sidekiq')
    end

    def callstack_entry_hash(callstack_entry)
      {
        path: callstack_entry[0],
        line: callstack_entry[1],
        method: callstack_entry[2]
      }
    end

    def split_stackline(callstack_line)
      split = callstack_line.rpartition(':in ')
      method = split.last.tr('`', '')
      split_2 = split.first.rpartition(':')
      path = split_2.first
      line = split_2.last
      [path, line, method].freeze
    end
  end
end
