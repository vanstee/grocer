require 'grocer'
require 'grocer/history'
require 'grocer/queue'
require 'grocer/ssl_connection'

module Grocer
  class Connection
    attr_reader :certificate, :checker, :gateway, :history, :passphrase, :port,
      :queue, :retries

    def initialize(options = {})
      @certificate = options.fetch(:certificate) { nil }
      @passphrase = options.fetch(:passphrase) { nil }
      @gateway = options.fetch(:gateway) { fail NoGatewayError }
      @port = options.fetch(:port) { fail NoPortError }
      @retries = options.fetch(:retries) { 3 }
      @queue = Queue.new
      @history = History.new

      wait_for_notifications
    end

    def enqueue(notification)
      queue.push(notification)
    end

    def wait_for_notifications
      Thread.new do
        loop do
          notification = queue.pop
          write(notification.to_bytes)
        end
      end
    end

    def rewind_to(identifier)
      notifications = history.pop_notifications_since(identifier)
      queue.push(*notifications)
    end

    def read(size = nil, buf = nil)
      with_connection do
        ssl.read(size, buf)
      end
    end

    def write(content)
      with_connection do
        ssl.write(content)
      end
    end

    def connect
      ssl.connect unless ssl.connected?
    end

    def error_response_handler(&block)
      @checker = ErrorResponseChecker.new(block)
      continually_check_for_responses
    end

    private

    def ssl
      @ssl_connection ||= build_connection
    end

    def build_connection
      Grocer::SSLConnection.new(certificate: certificate,
                                passphrase: passphrase,
                                gateway: gateway,
                                port: port)
    end

    def destroy_connection
      return unless @ssl_connection
      @ssl_connection.disconnect
      @ssl_connection = nil
    end

    def with_connection
      connect
      yield
    end

    def continually_check_for_responses
      with_connection do
        checker.continually_check_for_responses(ssl)
      end
    end
  end
end
