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
      attr_accessor :hostname
      # @return [Fixnum] the port to connect to
      attr_accessor :port
      # @return [Exception, nil] the last error that occurred, if any
      attr_reader :error

      class SSLValidationError < StandardError; end

      # @return [Float] the default connection timeout interval in seconds.
      DEFAULT_CONNECT_TIMEOUT_INTERVAL = 30

      def initialize(hostname, port, network, tls: true)
        @hostname = hostname
        @port = port
        @tls = tls
        @error = nil
        @network = network
        @connected = false
        @tx_queue = Async::Queue.new
      end

      def tls?
        @tls == true
      end

      # Check whether or not connection is established.
      def established?
        @connected == true
      end

      # Constructs and returns an async endpoint
      def endpoint
        if tls?
          Async::IO::Endpoint.ssl(hostname, port)
        else
          Async::IO::Endpoint.tcp(hostname, port)
        end
      end

      def connect(task = Async::Task.current)
        begin
          socket = endpoint.connect
          stream = Async::IO::Protocol::Line.new(Async::IO::Stream.new(socket), "\r\n")

          task.async do
            connection_established

            while (line = stream.read_line)
              received_line(line)
            end
          rescue EOFError => e
            @error = e
            logger.trace 'Socket received EOF', e
          ensure
            @connected = false
            @writer&.stop
            socket&.close
          end
        end

        @writer = task.async do
          @tx_queue.each { |line| stream.write_lines(line) }
        end
      end

      # Pushes +buf+ to the transaction queue
      def send_data(buf)
        @tx_queue.enqueue(buf)
      end

      # Called when a line was received, the connection sends it to the network
      # delegate which then sends it to the client.
      def received_line(line)
        message = IRCParser::Message.parse(line)
        logger.trace(message)
        @network.got_message(message)
      end

      private

      # Called when connection has been established.
      def connection_established
        @connected = true
        @network.connection_established
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
