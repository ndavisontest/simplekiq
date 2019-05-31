require 'active_support/core_ext/string'
require 'core_extensions/hash'
require 'sidekiq/cli'
require 'simplekiq/version'
require 'simplekiq/config'
require 'simplekiq/datadog'
require 'simplekiq/metadata_server'
require 'simplekiq/metadata_client'
require 'simplekiq/processor'
require 'simplekiq/queue_getter'
require 'simplekiq/redis_connection'
require 'simplekiq/retry_limit'
require 'simplekiq/worker'

module Simplekiq
  class Error < StandardError; end
  # Your code goes here...
  class << self
    def config
      Datadog.config
      Config.config
      MetadataClient.new.config
      MetadataServer.new.config
    end

    def app_name
      if defined?(::Rails)
        ::Rails.application.class.parent_name.underscore
      end
    end
  end
end

Simplekiq.config
