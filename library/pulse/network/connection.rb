# encoding: utf-8

module Pulse
  class Network
    class Connection
      attr_accessor :network

      def self.for network; new network end
      def established?; not @socket.nil? and not @socket.closed? end

      def initialize network = nil
        @network = network
      end

      def establish

      end
    end
  end
end
