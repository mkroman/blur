# encoding: utf-8

module Pulse
  class Client
    attr_accessor :options

    def initialize options
      @connection = Connection.new self
    end

    def connect
      @connection.establish
    end

    def got_command line
      puts "<< #{line}"
    end

    def connection_established connection
      connection.transmit :NICK, 'pulse'
      connection.transmit :USER, 'pulse', ?*, ?*, 'pulse'
    end
  end
end
