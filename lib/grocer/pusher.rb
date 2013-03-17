module Grocer
  class Pusher
    def initialize(connection)
      @connection = connection
    end

    def push(notification)
      @connection.queue.push(notification)
    end

    def error_response_handler(&block)
      @connection.error_response_handler(&block)
    end
  end
end
