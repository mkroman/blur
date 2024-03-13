# frozen_string_literal: true

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
      SSLValidationError = Class.new StandardError

      # @return [Float] the default connection timeout interval in seconds.
      DEFAULT_CONNECT_TIMEOUT_INTERVAL = 30

      # Check whether or not connection is established.
      def established?
        @connected == true
      end

      # EventMachine instantiates this class, and then sends event messages to
      # that instance.
      def initialize network
        @network = network
        @connected = false
        connect_timeout = network.options.fetch 'connect_timeout',
                                                DEFAULT_CONNECT_TIMEOUT_INTERVAL

        self.pending_connect_timeout = connect_timeout

        super
      end

      # Called when a new connection is being set up, all we're going to use
      # it for is to enable SSL/TLS on our connection.
      def post_init
        return unless @network.secure?

        verify_peer = (@network.options[:ssl_no_verify] ? false : true)
        start_tls verify_peer: verify_peer
      end

      # Called when a line was received, the connection sends it to the network
      # delegate which then sends it to the client.
      def receive_line line
        message = IRCParser::Message.parse line

        @network.got_message message
      end

      # Called when the SSL handshake was completed with the remote server,
      # the reason we tell the network that we're connected here is to ensure
      # that the SSL/TLS encryption succeeded before we start talking nonsense
      # to the server.
      def ssl_handshake_completed
        connected!
      end

      # Validates that the peer certificate has the correct fingerprint as
      # specified in the :fingerprint :ssl option.
      #
      # @note This doesn't support intermediate certificate authorities!
      # @raise [SSLValidationError] Raised if the specified fingerprint doesn't
      # match the certificates.
      def ssl_verify_peer peer_cert
        ssl_cert_file    = @network.options[:ssl_cert_file]
        peer_certificate = OpenSSL::X509::Certificate.new peer_cert

        if ssl_cert_file && !File.readable?(ssl_cert_file)
          raise SSLValidationError, 'Could not read the CA certificate file.'
        end

        if fingerprint_verification?
          fingerprint = @network.options[:ssl_fingerprint].to_s
          peer_fingerprint = cert_sha1_fingerprint peer_certificate

          if fingerprint != peer_fingerprint
            raise SSLValidationError,
                  "Expected fingerprint '#{fingerprint}', but got '#{peer_fingerprint}'"
          end
        end

        if certificate_verification?
          ca_certificate = OpenSSL::X509::Certificate.new File.read ssl_cert_file
          valid_signature = peer_certificate.verify ca_certificate.public_key

          raise SSLValidationError, 'Certificate verify failed' unless valid_signature
        end

        true
      end

      # Called once the connection is finally established.
      def connection_completed
        # We aren't completely connected yet if the connection is encrypted.
        connected! unless @network.secure?
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

      # Returns true if we're expected to verify the certificate fingerprint.
      def fingerprint_verification?
        !@network.options[:ssl_fingerprint].nil?
      end

      # Returns true if we should verify the peer certificate.
      def certificate_verification?
        !@network.options[:ssl_cert_file].nil?
      end

      # Get the hexadecimal representation of the certificates public key.
      def cert_sha1_fingerprint certificate
        fingerprint = OpenSSL::Digest::SHA1.hexdigest certificate.to_der

        # Format it the same way OpenSSL does.
        fingerprint = fingerprint.chars.each_slice(2).map(&:join).join ':'
        fingerprint.upcase
      end

      def ssl_fingerprint_error! peer_fingerprint
        fingerprint = @network.options[:ssl_fingerprint]

        raise SSLValidationError,
              "Expected fingerprint '#{fingerprint}' but got '#{peer_fingerprint}'"
      end
    end
  end
end
