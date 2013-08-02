# encoding: utf-8

module Blur
  class Network
    # The +Connection+ class inherits the LineAndText protocol bundled with
    # the eventmachine library.
    #
    # It merely acts as a receiving handler for all messages eventmachine throws
    # at it through its lifetime.
    #
    # @see EventMachine::Protocols::LineAndTextProtocol
    # @see EventMachine::Connection
    class Connection < EM::Protocols::LineAndTextProtocol
      # Check whether or not connection is established.
      def established?; @connected == true end

      # EventMachine instantiates this class, and then sends event messages to
      # that instance.
      def initialize network
        @network = network
        @connected = false

        super
      end

      # Called when a new connection is being set up, all we're going to use
      # it for is to enable SSL/TLS on our connection.
      def post_init
        start_tls if @network.secure?
      end

      # Called when a line was received, the connection sends it to the network
      # delegate which then sends it to the client.
      def receive_line line
        command = Command.parse line
        @network.got_command command
      end

      # Called when the SSL handshake was completed with the remote server,
      # the reason we tell the network that we're connected here is to ensure
      # that the SSL/TLS encryption succeeded before we start talking nonsense
      # to the server.
      def ssl_handshake_completed
        connected!
      end

      # Called once the connection is finally established.
      def connection_completed
        @network.connected! unless @network.secure?
      end

      # Called just as the connection is being terminated, either by remote or
      # local.
      def unbind
        @connected = false
        @network.disconnected!

        super
      end

    private
      # Called when connection has been established.
      def connected!
        @connected = true

        @network.connected!
      end
    end
  end
end
