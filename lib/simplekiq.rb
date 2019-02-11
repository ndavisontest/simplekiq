require "simplekiq/version"
require 'simplekiq/config'
require 'simplekiq/datadog'
require 'simplekiq/queue_getter'
require 'simplekiq/worker'
require 'string'

module Simplekiq
  class Error < StandardError; end
  # Your code goes here...
  class << self
    def config
      Datadog.config
      Config.config
    end

    def app_name
      if defined?(::Rails)
        ::Rails.application.class.parent_name.underscore
      end
    end
  end
end

Simplekiq.config
