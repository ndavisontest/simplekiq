module Simplekiq
  module Config
    class << self
      def config
        Simplekiq::Datadog.config
        Sidekiq.configure_server do |config|
          config.on(:startup) do
            if Sidekiq.options[:queues] == ['default']
              Sidekiq.options = Sidekiq.options.merge(queues: QueueGetter.queues)
            end
          end
          config.client_middleware do |chain|
            chain.add(Simplekiq::MetadataClient)
          end
        end
        Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.add(Simplekiq::MetadataServer)
          end
        end
      end
    end
  end
end
