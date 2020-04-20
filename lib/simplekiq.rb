require 'active_support/core_ext/string'
require 'core_extensions/hash'
require 'sidekiq/cli'
require 'simplekiq/config'
require 'simplekiq/datadog'
require 'simplekiq/enqueue_router'
require 'simplekiq/job_retry'
require 'simplekiq/metadata_client'
require 'simplekiq/metadata_server'
require 'simplekiq/monitored_enqueuer'
require 'simplekiq/monitored_worker'
require 'simplekiq/processor'
require 'simplekiq/queue_getter'
require 'simplekiq/redis_connection'
require 'simplekiq/version'
require 'simplekiq/worker'

module Simplekiq
  class Error < StandardError; end
  # Your code goes here...
  class << self
    def config
      Config.config
    end

    def app_name
      return unless defined?(::Rails)

      if ::Rails::VERSION::MAJOR >= 6
        ::Rails.application.class.module_parent_name.underscore
      else
        ::Rails.application.class.parent_name.underscore
      end
    end

    def enqueue(kwargs)
      Simplekiq::EnqueueRouter.instance.enqueue(kwargs)
    end
  end
end

Simplekiq.config
