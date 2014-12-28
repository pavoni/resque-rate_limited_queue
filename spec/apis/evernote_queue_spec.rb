require 'spec_helper'
require 'resque/rate_limited_queue'

class RateLimitDuration
  def self.seconds
    60
  end
end

class RateLimitedTestQueueEn
  def self.perform(succeed)
    raise(Evernote::EDAM::Error::EDAMSystemException, rateLimitDuration: RateLimitDuration) unless succeed
  end
end

describe Resque::Plugins::RateLimitedQueue::EvernoteQueue do
  before do
    Resque::Plugins::RateLimitedQueue::EvernoteQueue.stub(:paused?).and_return(false)
  end
  describe 'enqueue' do
    it 'enqueues to the correct queue with the correct parameters' do
      Resque.should_receive(:enqueue_to).with(
        :evernote_api,
        Resque::Plugins::RateLimitedQueue::EvernoteQueue,
        RateLimitedTestQueueEn.to_s,
        true)
      Resque::Plugins::RateLimitedQueue::EvernoteQueue
        .enqueue(RateLimitedTestQueueEn, true)
    end
  end

  describe 'perform' do
    before do
      Resque.inline = true
    end
    context 'with everything' do
      it 'calls the class with the right parameters' do
        RateLimitedTestQueueEn.should_receive(:perform).with('test_param')
        Resque::Plugins::RateLimitedQueue::EvernoteQueue
          .enqueue(RateLimitedTestQueueEn, 'test_param')
      end
    end

    context 'with rate limit exception' do
      before do
        Resque::Plugins::RateLimitedQueue::EvernoteQueue.stub(:rate_limited_requeue)
      end
      it 'pauses queue when request fails' do
        Resque::Plugins::RateLimitedQueue::EvernoteQueue.should_receive(:pause_for)
        Resque::Plugins::RateLimitedQueue::EvernoteQueue
          .enqueue(RateLimitedTestQueueEn, false)
      end
    end
  end
end

