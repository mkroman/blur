# encoding: utf-8

module Blur
  class Network 
    class Connection
      def established?; @socket and not @socket.closed? end
      
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

      def enable_ssl verification
        @secure = true

        context = OpenSSL::SSL::SSLContext.new
        context.set_params verify_mode: verification

        sslsocket = OpenSSL::SSL::SSLSocket.new @socket, context
        sslsocket.sync = true
        sslsocket.connect_nonblock
      end
      
      def terminate
        @socket = nil if @socket.close
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
