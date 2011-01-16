# encoding: utf-8

module Blur
  class Network
    class ConnectionError < StandardError; end

    attr_accessor :host, :port, :secure, :delegate, :connection

    def connected?; @connection.established? end

    def initialize host, port = 6667, secure = false
      @host, @port, @secure = host, port, secure
      @channels = []

      @connection = Connection.new self
    end

    def connect
      puts "Connecting to #{self} …"

      @connection.establish

      transmit :NICK, "test#{rand 9999999999}"
      transmit :USER, :test_bot, ?*, ?*, "ddddddd d"
    end

    def transmit name, *arguments
      command = Command.new name, arguments
      puts "-> \e[1m#{self}\e[0m | #{command}"

      @connection.transmit command
    end

    def to_s; "#<#{self.class.name}: #{@host}:#{@port}>" end
    def transcieve; @connection.transcieve end
    def got_command command; @delegate.got_command self, command end
  end
end
