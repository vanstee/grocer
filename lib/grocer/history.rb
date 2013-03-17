require 'thread'

module Grocer
  class History
    attr_reader :history, :lock

    def initialize
      @history = []
      @lock = Mutex.new
    end

    def push(*elements)
      synchronize do
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
