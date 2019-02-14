module Simplekiq
  module QueueGetter
    class << self
      def queues
        raise 'Workers declared in config_file' unless config_file_queues.nil?
        load_workers!

        worker_classes.collect do |klass|
          [queue_name(klass)] * priority(klass)
        end.flatten
      end

      private

      def queue_name(klass)
        klass.sidekiq_options['queue']
      end

      def priority(klass)
        klass.sidekiq_options['priority'] || 1
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

      def config_file_queues
        YAML.load(
          ERB.new(
            File.read(
              Sidekiq.options[:config_file]
            )
          ).result
        )[:queues] rescue nil
      end
    end
  end
end
