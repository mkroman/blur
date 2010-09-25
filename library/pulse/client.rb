# encoding: utf-8

require 'pulse/handling'

module Pulse
  class Client
    include Handling

    def initialize options
      @channels   = []
      @callbacks  = {}
      @connection = Connection.new self
    end

    def connect
      trap 2 do; transmit :QUIT, "I was interrupted" end
      @connection.establish
    end

    def got_command command
      name = :"got_#{command.name.downcase}"
      puts "<< #{command}"

      if respond_to? name
        __send__ name, command
      end
    end

    def connection_established connection
      puts "Connection has been established."

      transmit :NICK, 'pulse'
      transmit :USER, 'pulse', ?*, ?*, 'pulse'
    end

    def connection_terminated connection
      puts "The connection was terminated."
    end

  private
    def emit name, *args
      @callbacks[name].each do |callback|
        callback.call *args
      end if @callbacks[name]
    end

    def catch name, &block
      (@callbacks[name] ||= []) << block
    end

    def transmit name, *args
      @connection.transmit name, *args
    end
  end
end
