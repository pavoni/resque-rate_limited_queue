require 'spec_helper'
require 'resque/rate_limited_queue'

class RateLimitedTestQueue
  extend Resque::Plugins::RateLimitedQueue

  @queue = :test

  def self.perform(succeed)
    rate_limited_requeue(self, succeed) unless succeed
  end

  def self.queue_name
    @queue.to_s
  end

  def self.queue
    @queue
  end
end

describe Resque::Plugins::RateLimitedQueue do
  it 'should be compliance with Resque::Plugin document' do
    expect { Resque::Plugin.lint(Resque::Plugins::RateLimitedQueue) }.to_not raise_error
  end

  shared_examples_for 'queue' do |queue_suffix|
    it 'should queue to the correct queue' do
      queue_param = queue_suffix.empty? ? RateLimitedTestQueue.queue : "#{RateLimitedTestQueue.queue_name}#{queue_suffix}"
      Resque.should_receive(:enqueue_to).with(queue_param, nil, nil)
      RateLimitedTestQueue.rate_limited_enqueue(nil, nil)
    end
  end

  context 'when queue is not paused' do
    before do
      RateLimitedTestQueue.stub(:paused?).and_return(false)
    end

    describe 'enqueue' do
      include_examples 'queue', ''
    end

    describe 'paused?' do
      it { RateLimitedTestQueue.paused?.should be false }
    end

    describe 'perform' do
      it 'should requeue the job on failure' do
        Resque.should_receive(:enqueue_to)
        RateLimitedTestQueue.perform(false)
      end

      it 'should not requeue the job on success' do
        Resque.should_not_receive(:enqueue_to)
        RateLimitedTestQueue.perform(true)
      end

    end

    describe 'pause' do
      it 'should rename the queue to paused' do
        Resque.redis.should_receive(:renamenx).with("queue:#{RateLimitedTestQueue.queue_name}", "queue:#{RateLimitedTestQueue.queue_name}_paused")
        RateLimitedTestQueue.pause
      end
    end

    describe 'un_pause' do
      it 'should not unpause the queue' do
        Resque.redis.should_not_receive(:renamenx).with("queue:#{RateLimitedTestQueue.queue_name}", "queue:#{RateLimitedTestQueue.queue_name}_paused")
        RateLimitedTestQueue.un_pause
      end
    end

    describe 'pause_until' do
      before do
        Resque.redis.stub(:renamenx).and_return(true)
      end

      it 'should pause the queue' do
        RateLimitedTestQueue.should_receive(:pause)
        RateLimitedTestQueue.pause_until(Time.now + (5 * 60 * 60))
      end

      it 'should schedule an unpause job' do
        Resque::Plugins::RateLimitedQueue::UnPause.should_receive(:enqueue)
          .with(nil, 'RateLimitedTestQueue')
        RateLimitedTestQueue.pause_until(nil)
      end
    end
  end

  context 'when queue is paused' do
    before do
      RateLimitedTestQueue.stub(:paused?).and_return(true)
    end

    describe 'enqueue' do
      include_examples 'queue', '_paused'
    end

    describe 'paused?' do
      it { RateLimitedTestQueue.paused?.should be true }
    end

    describe 'perform' do
      it 'should not execute the block' do
        Resque.should_receive(:enqueue_to).with("#{RateLimitedTestQueue.queue_name}_paused", RateLimitedTestQueue, true)
        RateLimitedTestQueue.should_not_receive(:perform)
        RateLimitedTestQueue.around_perform_with_check_and_requeue(true)
      end
    end

    describe 'un_pause' do
      it 'should rename the queue to live' do
        Resque.redis.should_receive(:renamenx).with("queue:#{RateLimitedTestQueue.queue_name}_paused", "queue:#{RateLimitedTestQueue.queue_name}")
        RateLimitedTestQueue.un_pause
      end
    end
  end

  describe 'find_class' do
    it 'works with symbol' do
      RateLimitedTestQueue.find_class(RateLimitedTestQueue).should eq RateLimitedTestQueue
    end

    it 'works with simple string' do
      RateLimitedTestQueue.find_class('RateLimitedTestQueue').should eq RateLimitedTestQueue
    end

    it 'works with complex string' do
      RateLimitedTestQueue.find_class('Resque::Plugins::RateLimitedQueue').should eq Resque::Plugins::RateLimitedQueue
    end
  end

  context 'with redis errors' do
    before do
      RateLimitedTestQueue.stub(:paused?).and_return(true)
    end
    context 'with not found error' do
      before do
        Resque.redis.stub(:renamenx).and_raise(Redis::CommandError.new('ERR no such key'))
      end

      describe 'pause' do
        it 'should not throw exception' do
          expect { RateLimitedTestQueue.pause }.to_not raise_error
        end
      end

      describe 'un_pause' do
        it 'should not throw exception' do
          expect { RateLimitedTestQueue.un_pause }.to_not raise_error
        end
      end

    end

    context 'with other errror' do
      before do
        Resque.redis.stub(:renamenx).and_raise(Redis::CommandError.new('ERR something else'))
      end

      describe 'pause' do
        it 'should throw exception' do
          expect { RateLimitedTestQueue.pause }.to raise_error(Redis::CommandError)
        end
      end

      describe 'un_pause' do
        it 'should throw exception' do
          expect { RateLimitedTestQueue.un_pause }.to raise_error(Redis::CommandError)
        end
      end
    end
  end
end
