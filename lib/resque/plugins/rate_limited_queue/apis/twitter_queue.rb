require 'twitter'

module Resque
  module Plugins
    module RateLimitedQueue
      class TwitterQueue
        extend Resque::Plugins::RateLimitedQueue
        @queue = :twitter_api

        def self.perform(klass, *params)
          find_class(klass).perform(*params)
        rescue Twitter::Error::TooManyRequests,
               Twitter::Error::EnhanceYourCalm => e
          pause_for(Time.now + e.rate_limit.reset_in, name)
          rate_limited_requeue(self, klass, *params)
        end

        def self.enqueue(klass, *params)
          rate_limited_enqueue(self, klass, *params)
        end
      end
    end
  end
end
