# encoding: utf-8

module Pulse
  class Network
    class ConnectionError < StandardError; end

    attr_accessor :host, :port

    def to_s; "#@host:#@port" end
    def secure?; @secure == true end
    def connected?; @connection.established? end

    def self.for string
      host, port = string.split ?:
      new host, port || 6667, false
    end

    def initialize host, port = 6667, secure = false
      @host, @port, @secure = host, port, secure

      @connection = Connection.new self
    end

    def connect
      @connection.establish unless connected?
    end
  end
end
