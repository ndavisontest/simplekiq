require 'sidekiq/testing'

module Simplekiq
  module Worker
    module ClassMethods
      include Sidekiq::Worker::ClassMethods

      def execute_job(worker, cloned_args)
        raise ArgumentError.new("wrong number of arguments (given #{cloned_args.size}, expected 1)") unless cloned_args.size == 1
        params = cloned_args.first.deep_symbolize_all_keys
        worker.perform(params)
      end
    end
  end
end
