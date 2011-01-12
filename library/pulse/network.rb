# encoding: utf-8

module Pulse
  class Network
    class ConnectionError < StandardError; end

    attr_accessor :host, :port, :secure, :delegate

    def connected?; false end

    def initialize host, port = 6667, secure = false
      @host, @port, @secure = host, port, secure

      @connection = Connection.new self
    end

    def connect
      puts "Connecting to #{self} …"
    end

    def transcieve
      puts "Transcieving data for #{self} …"
    end
  end
end
