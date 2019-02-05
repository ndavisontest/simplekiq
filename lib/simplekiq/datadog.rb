require 'sidekiq'
require 'sidekiq/cli'
require 'sidekiq-datadog'

module Simplekiq
  module Datadog
    def self.config
      Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.add(
            Sidekiq::Middleware::Server::Datadog,
            tags: [
              ->(worker, job, queue, error) {
                "service:#{Rails.application.class.parent_name.downcase rescue 'undefined'}"
              }
            ]
           )
        end
      end
    end
  end
end
