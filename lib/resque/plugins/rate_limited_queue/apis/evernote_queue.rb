require 'evernote-thrift'

module Resque
  module Plugins
    module RateLimitedQueue
      class EvernoteQueue
        extend Resque::Plugins::RateLimitedQueue
        @queue = :evernote_api

        def self.perform(klass, *params)
          find_class(klass).perform(*params)
        rescue Evernote::EDAM::Error::EDAMSystemException => e
          pause_for(Time.now + 60 * e.rateLimitDuration.seconds, name)
          rate_limited_requeue(self, klass, *params)
        end

        def self.enqueue(klass, *params)
          rate_limited_enqueue(self, klass, *params)
        end
      end
    end
  end
end
