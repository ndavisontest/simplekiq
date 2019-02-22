require 'sidekiq'
require 'sidekiq-datadog'

module Simplekiq
  class Datadog
    class << self
      def config
        Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.add(
              Sidekiq::Middleware::Server::Datadog,
              tags: [
                ->(worker, job, queue, error) {
                  "service:#{app_name}"
                }
              ]
             )
          end
        end
      end

      def app_name
        Simplekiq.app_name || 'undefined'
      end
    end
  end
end
