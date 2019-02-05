require "simplekiq/version"
require 'simplekiq/datadog'

module Simplekiq
  class Error < StandardError; end
  # Your code goes here...
  def self.start
    Datadog.config
  end

end

Simplekiq.start
