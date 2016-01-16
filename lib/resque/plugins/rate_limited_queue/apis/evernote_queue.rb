require 'evernote-thrift'

module Resque
  module Plugins
    module RateLimitedQueue
      class EvernoteQueue < BaseApiQueue
        @queue = :evernote_api

        def self.perform(klass, *params)
          super
        rescue Evernote::EDAM::Error::EDAMSystemException => e
          raise unless e.errorCode == Evernote::EDAM::Error::EDAMErrorCode::RATE_LIMIT_REACHED
          pause_until(Time.now + 60 * e.rateLimitDuration.seconds)
          rate_limited_requeue(self, klass, *params)
        end
      end
    end
  end
end
