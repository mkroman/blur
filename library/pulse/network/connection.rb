# encoding: utf-8

module Pulse
  class Network 
    class Connection
      def connected?; not @socket.nil? and not @socket.closed? end

      def initialize network
        @network, @buffer = network, ''
      end

      def connect
        @socket = TCPSocket.new @network.host, @network.port
      end

      def transcieve
        @buffer.<< @socket.read_nonblock 512
      end
    end
  end
end
