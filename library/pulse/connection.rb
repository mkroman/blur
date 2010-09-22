# encoding: utf-8

module Pulse
  class Connection
  
    DefaultHost = 'irc.maero.dk'
    DefaultPort = 6667

    def initialize delegate
      @delegate = delegate
      @queue = Queue.new
    end

    def establish
      TCPSocket.open DefaultHost, DefaultPort do |socket|
        Thread.start socket, &@queue.method(:process)

        until socket.eof?
          @delegate.got_command Command.parse socket.gets
        end
      end
    end

    def transmit name, *arguments
      Command.new(name, arguments).tap { |this| @queue << this }
    end
  end
end
