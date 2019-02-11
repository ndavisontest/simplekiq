require 'sidekiq'

module Simplekiq
  module Worker
    include Sidekiq::Worker

    def self.included(base)
      raise ArgumentError, "You cannot include Sidekiq::Worker in an ActiveJob: #{base.name}" if base.ancestors.any? {|c| c.name == 'ActiveJob::Base' }
      base.extend(ClassMethods)

      base.sidekiq_class_attribute :sidekiq_options_hash
      base.sidekiq_class_attribute :sidekiq_retry_in_block
      base.sidekiq_class_attribute :sidekiq_retries_exhausted_block
    end

    module ClassMethods
      include Sidekiq::Worker::ClassMethods

      def get_sidekiq_options
        self.sidekiq_options_hash ||= Sidekiq.default_worker_options.merge(
          'queue' => queue_name
        )
      end

      private

      def queue_name
        "#{app_name}#{dash}#{worker_name}"
      end

      def dash
        '-' unless app_name.nil?
      end

      def worker_name
        name.chomp('Worker').underscore
      end

      def app_name
        Simplekiq.app_name
      end
    end
  end
end
