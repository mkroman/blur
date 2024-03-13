# frozen_string_literal: true

require 'async/queue'

module Blur
  class Network
    # The +Connection+ class inherits the LineAndText protocol bundled with
    # the eventmachine library.
    #
    # It merely acts as a receiving handler for all messages eventmachine throws
    # at it through its lifetime.
    class Connection
      include SemanticLogger::Loggable

      # @return [String] the hostname to connect to
      attr_accessor :host

      # @return [Fixnum] the port to connect to
      attr_accessor :port

      class SSLValidationError < StandardError; end

      # @return [Float] the default connection timeout interval in seconds.
      DEFAULT_CONNECT_TIMEOUT_INTERVAL = 30

      # Check whether or not connection is established.
      def established?
        @connected == true
      end

      def initialize(host, port, network, secure: true)
        @host = host
        @port = port
        @secure = secure
        @network = network
        @connected = false

        connect_timeout = network.options.fetch 'connect_timeout',
                                                DEFAULT_CONNECT_TIMEOUT_INTERVAL
        @send_queue = Async::Queue.new

        # self.pending_connect_timeout = connect_timeout
      end

      # Constructs and returns an async endpoint.
      def endpoint
        if @secure
          Async::IO::Endpoint.ssl(host, port)
        else
          Async::IO::Endpoint.tcp(host, port)
        end
      end

      def connect(task = Async::Task.current)
        begin
          socket = endpoint.connect
          stream = Async::IO::Protocol::Line.new(Async::IO::Stream.new(socket))

          task.async do
            @network.connected!

            while (line = stream.read_line)
              receive_line(line)
            end
          rescue EOFError => e
            logger.trace 'Socket received EOF', e
          ensure
            if socket
              logger.trace('Closing socket')
              socket.close
            end
          end
        end

        task.async do
          while (line = @send_queue.dequeue)
            stream.write_lines(line)
          end
        end
      end

      def send_data buf
        @send_queue.enqueue buf
      end

      # Called when a line was received, the connection sends it to the network
      # delegate which then sends it to the client.
      def receive_line(line)
        message = IRCParser::Message.parse(line)
        logger.trace(message)
        @network.got_message(message)
      end

      private

      # Called when connection has been established.
      def connected!
        @connected = true

        @network.connected!
      end

      # Returns true if we're expected to verify the certificate fingerprint.
      def fingerprint_verification?
        !@network.options[:ssl_fingerprint].nil?
      end

      # Returns true if we should verify the peer certificate.
      def certificate_verification?
        !@network.options[:ssl_cert_file].nil?
      end
    end
  end
end
