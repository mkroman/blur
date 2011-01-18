# encoding: utf-8

module Blur
  class Network 
    class Connection
      def established?; @socket and not (@socket.closed? or @socket.eof?) end
      
      def initialize delegate, host = nil, port = nil
        @host     = host
        @port     = port
        @queue    = []
        @buffer   = ""
        @socket   = nil
        @delegate = delegate
      end
      
      def establish
        @socket = TCPSocket.new @host, @port
      end
      
      def terminate
        @socket.close
        @socket = nil
        @buffer = ""
        @queue.clear
      end
      
      def transmit command
        @queue.push command
      end
      
      def transcieve
        readable, writable = IO.select [@socket], [@socket]
        
        # If the socket is ready to recieve, do so.
        if socket = readable.first
          @buffer.<< socket.read_nonblock 512
          
          while index = @buffer.index(?\n)
            command = Command.parse @buffer.slice! 0..index
            @delegate.got_command command
          end
        end
        
        # If it's ready to write, do that too until the outoing queue is empty.
        if socket = writable.first
          socket.write_nonblock "#{command}\n" while command = @queue.shift
        end
      end
    end
  end
end
