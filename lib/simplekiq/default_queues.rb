module Simplekiq
  module DefaultQueues
    LOW_PRIORITY = 1
    MEDIUM_PRIORITY = 5
    HIGH_PRIORITY = 10
    CRITICAL_PRIORITY = 20

    class << self
      def queues
        return [] if app_name.nil?

        queue_types.collect do |queue_type, priority|
          [queue_name(queue_type)] * priority
        end.flatten
      end

      private

      def queue_name(queue_type)
        "#{app_name}-#{queue_type}"
      end

      def queue_types
        {
          'low' => LOW_PRIORITY,
          'medium' => MEDIUM_PRIORITY,
          'high' => HIGH_PRIORITY,
          'critical' => CRITICAL_PRIORITY
        }
      end

      def app_name
        Simplekiq.app_name
      end
    end
  end
end
