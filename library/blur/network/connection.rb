# encoding: utf-8

module Blur
  class Network
    # The +Connection+ class is a tedious wrapper for the socket I/O-handling.
    #
    # When I originally started writing Blur, I wanted it to be perfect.
    # I wanted non-blocking connections, proper SSL-transmissions and 
    # easy extensibility.
    #
    # I had no actual experience with non-blocking network before, so I
    # wrote this pile of.. code. I'm amazed that it works and it doesn't crash
    # the universe.
    class Connection
      # Check to see if the socket connection is alive.
      def established?; @socket and not @socket.closed? end
      
      # Instantiate a new connection with a delegate, a host, and a port.
      def initialize delegate, host = nil, port = nil
        @host     = host
        @port     = port
        @queue    = []
        @buffer   = ""
        @socket   = nil
        @delegate = delegate
      end
      
      # Attempt to establish a new connection.
      def establish
        @socket = TCPSocket.new @host, @port
      end

      # “Forcefully” adapt SSL to the TCP connection.
      #
      # @todo Make this work without it throwing a massive fight.
      def enable_ssl verification
        @secure = true

        context = OpenSSL::SSL::SSLContext.new
        context.set_params verify_mode: verification

        sslsocket = OpenSSL::SSL::SSLSocket.new @socket, context
        sslsocket.sync = true
        sslsocket.connect #_nonblock
        @socket = sslsocket
      end
      
      # Terminate the connection, clear the buffer and the command-queue.
      def terminate
        @socket = nil if @socket.close
        @buffer.clear
        @queue.clear
      end
      
      # Push a command into the command-queue, which will then be consecutively.
      def transmit command
        @queue.push command
      end
      
      # Recieve and send data if there is any available, then store it the
      # buffer.
      #
      # @todo Implement *proper* non-blocking connections, as this is just
      #   fucking stupid.
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
          while command = @queue.shift
            socket.write_nonblock "#{command}\n"
          end
        end

      rescue Errno::EAGAIN, Errno::EWOULDBLOCK
        puts "Insecure connection would block"
      rescue OpenSSL::SSL::SSLError
        if $!.message == "read would block"
          puts "Secure connection would block"
        else
          raise $!
        end
      end
    end
  end
end
