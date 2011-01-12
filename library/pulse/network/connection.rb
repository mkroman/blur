# encoding: utf-8

module Pulse
  class Network 
    class Connection

      def established?; not @socket.nil? and not @socket.closed? end

      def initialize network
        @network, @buffer, @socket = network, '', nil
      end

      def establish
        @socket = TCPSocket.new @network.host, @network.port
      end

      def transcieve
        readable, writable = IO.select [@socket]

        if socket = readable.first and not socket.eof?
          @buffer.<< socket.read_nonblock 512

          if @buffer.include? ?\n
            command = Command.parse @buffer.slice! 0..@buffer.index(?\n)

            @network.got_command command
          end
        end
      end
    end
  end
end
