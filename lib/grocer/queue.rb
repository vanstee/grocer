require 'thread'

module Grocer
  class Queue
    attr_reader :queue, :lock, :condition

    def initialize
      @queue = []
      @lock = Mutex.new
      @condition = Condition.new
    end

    def pop
      synchronize do
        wait_for_signal while queue.empty?
        queue.pop
      end
    end

    def push(*elements)
      synchronize do
        queue.push(*elements)
        signal
      end
    end

    def unshift(*elements)
      synchronize do
        queue.unshift(*elements)
        signal
      end
    end

    private

    def wait_for_signal
      condition.wait(lock)
    end

    def signal
      condition.signal
    end

    def synchronize(&block)
      lock.synchronize(&block)
    end
  end
end
