module Resque
  module Plugins
    module RateLimitedQueue
      RESQUE_PREFIX = 'queue:'
      MUTEX = 'Resque::Plugins::RateLimitedQueue'


      def around_perform_with_check_and_requeue(*params)
        paused = false
        with_lock do
          paused = paused?
          Resque.enqueue_to(paused_queue_name, self, *params) if paused
        end
        return if paused
        yield
      end

      def rate_limited_enqueue(klass, *params)
        with_lock do
          if paused?
            Resque.enqueue_to(paused_queue_name, klass, *params)
          else
            Resque.enqueue_to(@queue, klass, *params)
          end
        end
      end

      def rate_limited_requeue(klass, *params)
        # split from above to make it easy to stub for testing
        rate_limited_enqueue(klass, *params)
      end

      def pause_for(timestamp)
        pause
        UnPause.enqueue(timestamp, name)
      end

      def un_pause
        with_lock do
          if paused?
            begin
              Resque.redis.renamenx(RESQUE_PREFIX + paused_queue_name, RESQUE_PREFIX + @queue.to_s)
            rescue Redis::CommandError => e
              raise unless e.message == 'ERR no such key'
            end
          end
        end
      end

      def pause
        Resque.redis.renamenx(RESQUE_PREFIX + @queue.to_s, RESQUE_PREFIX + paused_queue_name)
      rescue Redis::CommandError => e
        raise unless e.message == 'ERR no such key'
      end

      def paused?
        Resque.redis.exists(RESQUE_PREFIX + paused_queue_name)
      end

      def paused_queue_name
        @queue.to_s + '_paused'
      end

      def with_lock
        if Resque.inline
          yield
        else
          RedisMutex.with_lock(MUTEX, block: 60, expire: 120) { yield }
        end
      end

      def class_from_string(str)
        str.split('::').inject(Object) do |mod, class_name|
          mod.const_get(class_name)
        end
      end
    end
  end
end
