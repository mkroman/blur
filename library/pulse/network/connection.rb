# encoding: utf-8

module Pulse
  class Network
    class Connection
      attr_accessor :network

      def established?; @socket.nil? ? nil : !@socket.closed? end

      def initialize network = nil
        @network = network
      end

      def establish
        unless established?
          puts "Connecting to #@network …"

          @socket = TCPSocket.new @network.host, @network.port
        else
          raise ConnectionError, "Connection has already been established"
        end
      end
    end
  end
end
