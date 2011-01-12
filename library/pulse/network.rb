# encoding: utf-8

module Pulse
  class Network
    class ConnectionError < StandardError; end

    attr_accessor :host, :port, :secure, :delegate

    def connected?; @connection and @connection.established? end

    def initialize host, port = 6667, secure = false
      @host, @port, @secure = host, port, secure

      @channels = []

      @connection = Connection.new self
    end

    def connect
      puts "Connecting to #{self} …"

      @connection.establish
    end

    def transcieve; @connection.transcieve end

    def got_command command
      puts "#{self}: #{command.inspect}"
    end
  end
end
