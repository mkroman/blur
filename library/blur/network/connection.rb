# encoding: utf-8

module Blur
  class Network 
    class Connection
      def established?; @socket and not (@socket.closed? or @socket.eof?) end
      
      def initialize delegate, host = nil, port = nil, secure = false
        @host     = host
        @port     = port
        @queue    = []
        @buffer   = ""
        @socket   = nil
        @secure   = secure
        @delegate = delegate
      end
      
      def establish
        @socket = TCPSocket.new @host, @port

        if @secure
          require 'openssl'

          @socket = OpenSSL::SSL::SSLSocket.new @socket, OpenSSL::SSL::SSLContext.new
          @socket.connect
        end
      end
      
      def terminate
        if @socket.close
          @socket = nil
        end

        @buffer.clear
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
      rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      rescue OpenSSL::SSL::SSLError
        raise $! unless $!.message == "read would block" # Really, OpenSSL?
      end
    end
  end
end
