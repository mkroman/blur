# encoding: utf-8

module Blur
  class Network 
    class Connection

      def established?; @socket and !(@socket.closed? or @socket.eof?) end

      def initialize network
        @network, @buffer, @socket, @queue = network, "", nil, []
      end

      def establish
        @socket = TCPSocket.new @network.host, @network.port
      end

      def transmit command; @queue << command end

      def transcieve
        readable, writable = IO.select [@socket], [@socket]

        readable.each do |socket|
          @buffer.<< socket.read_nonblock 512

          while index = @buffer.index(?\n)
            command = Command.parse @buffer.slice! 0..index

            @network.got_command command
          end
        end

        writable.each do |socket|
          while command = @queue.shift
            socket.write_nonblock "#{command}\n"
          end
        end
        
      end
    end
  end
end
