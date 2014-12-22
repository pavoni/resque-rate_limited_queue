require 'spec_helper'
require 'resque_rate_limited_queue'

class RateLimitedTestQueue
end

describe Resque::Plugins::RateLimitedQueue::UnPause do
  describe 'perform' do
    it 'unpauses the queue' do
      RateLimitedTestQueue.should_receive(:un_pause)
      Resque::Plugins::RateLimitedQueue::UnPause.perform(RateLimitedTestQueue)
    end
  end

  describe 'enqueue' do
    before { Resque.stub(:respond_to?).and_return(true) }
    context 'with no queue defined' do
      it 'does not queue the job' do
        Resque.should_not_receive(:enqueue_at_with_queue)
        Resque::Plugins::RateLimitedQueue::UnPause.enqueue(Time.now, RateLimitedTestQueue)
      end
    end

    context 'with queue defined' do
      before { Resque::Plugins::RateLimitedQueue::UnPause.queue = :queue_name }
      it 'queues the job' do
        Resque.should_receive(:enqueue_at_with_queue).with(
          :queue_name,
          nil,
          Resque::Plugins::RateLimitedQueue::UnPause,
          RateLimitedTestQueue)

        Resque::Plugins::RateLimitedQueue::UnPause.enqueue(nil, RateLimitedTestQueue)
      end
    end
  end

end
