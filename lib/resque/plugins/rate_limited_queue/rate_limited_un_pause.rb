module Resque
  module Plugins
    module RateLimitedQueue
      class UnPause
        @queue = nil

        class << self
          attr_writer(:queue)

          def use?
            Resque.respond_to?(:enqueue_at_with_queue) && @queue
          end

          def enqueue(timestamp, klass)
            # If Resque scheduler is installed and queue is set - use it to queue a wake up job
            return unless use?
            Resque.enqueue_at_with_queue(
              @queue,
              timestamp,
              Resque::Plugins::RateLimitedQueue::UnPause,
              klass
            )
          end

          def perform(klass)
            class_from_string(klass.to_s).un_pause
          end

          def class_from_string(str)
            return Object.const_get(str) unless str.include?('::')
            str.split('::').reduce(Object) do |mod, class_name|
              mod.const_get(class_name)
            end
          end
        end
      end
    end
  end
end
