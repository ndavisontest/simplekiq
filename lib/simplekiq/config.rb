module Simplekiq
  module Config
    class << self
      def config
        Sidekiq.configure_server do |config|
          config.on(:startup) do
            if Sidekiq.options[:queues] == ['default']
              Sidekiq.options = Sidekiq.options.merge(queues: QueueGetter.queues)
            end
          end
        end
      end
    end
  end
end

