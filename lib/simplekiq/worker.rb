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
        self.sidekiq_options_hash ||=
          Sidekiq.default_worker_options.merge(
            'queue' => "#{::Rails.application.class.parent_name.downcase}-".concat(self.name.chomp('Worker'))
        )
      end
    end
  end
end
