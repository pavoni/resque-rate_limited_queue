module Resque
  module Plugins
    module RateLimitedQueue
      class BaseApiQueue
        extend Resque::Plugins::RateLimitedQueue
        def self.perform(klass, *params)
          find_class(klass).perform(*params)
        end

        def self.enqueue(klass, *params)
          rate_limited_enqueue(self, klass.to_s, *params)
        end
      end
    end
  end
end
