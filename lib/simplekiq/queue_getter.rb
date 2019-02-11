module Simplekiq
  module QueueGetter
    class << self
      def queues
        load_workers!

        worker_classes.collect do |klass|
          queue_name(klass)
        end
      end

      private

      def queue_name(klass)
        klass.sidekiq_options['queue']
      end

      def worker_classes
        ObjectSpace.each_object(Class).select do |klass|
          klass.included_modules.include? Simplekiq::Worker
        end
      end

      def load_workers!
        Dir[File.join('app', 'workers', '**', '*.rb')].each do |file|
          load file
        end
      end
    end
  end
end
