require 'angellist_api'

module Resque
  module Plugins
    module RateLimitedQueue
      class AngellistQueue < BaseApiQueue
        WAIT_TIME = 60
        @queue = :angellist_api

        def self.perform(klass, *params)
          super
        rescue AngellistApi::Error::TooManyRequests
          pause_for(Time.now + (60 * 60))
          rate_limited_requeue(self, klass, *params)
        end
      end
    end
  end
end
