require 'twitter'

module Resque
  module Plugins
    module RateLimitedQueue
      class TwitterQueue < BaseApiQueue
        @queue = :twitter_api

        def self.perform(klass, *params)
          super
        rescue Twitter::Error::TooManyRequests,
               Twitter::Error::EnhanceYourCalm => e
          pause_for(Time.now + e.rate_limit.reset_in)
          rate_limited_requeue(self, klass, *params)
        end
      end
    end
  end
end
