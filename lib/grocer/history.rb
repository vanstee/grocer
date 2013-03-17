require 'thread'

module Grocer
  class History
    DEFAULT_SIZE = 100

    attr_reader :history, :lock, :size

    def initialize(options = {})
      @history = []
      @lock = Mutex.new
      @size = options.fetch(:size, DEFAULT_SIZE)
    end

    def push(*elements)
      synchronize do
        if queue.size + elements.size > size
          extra = queue.size + elements.size - size
          elements.shift(extra)
        end

        queue.push(*elements)
      end
    end

    def pop_notifications_since(identifier)
      synchronize do
        index = history.index do |notification|
          notification.identifier == identifier
        end

        if index
          notifications = history.slice!(Range.new(index, -1))
          notifications.unshift
          notifications
        end
      end
    end

    private

    def synchronize(&block)
      lock.synchronize(&block)
    end
  end
end
