# encoding: utf-8

module Pulse
  class Connection
    def initialize delegate, settings
      @delegate = delegate
      @settings = settings
      @queue    = Queue.new
    end

    def establish
      TCPSocket.open @settings.hostname, @settings.port do |socket|
        @socket = socket

        Thread.start socket, &@queue.method(:process)
        @delegate.connection_established self

        until socket.eof?
          @delegate.got_command Command.parse socket.gets
        end
      end

      @delegate.connection_terminated self
    end

    def transmit name, *arguments
      if established?
        Command.new(name, arguments).tap { |this| @queue << this }
      else
        raise ConnectionError, "Connection has not been established"
      end
    end

    def established?; not @socket.nil? and not @socket.closed? end

    def close
      if established?
        @socket.close
      else
        raise ConnectionError, "Connection is already closed"
      end
    end
  end
end
