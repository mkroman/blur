# encoding: utf-8

require 'pulse/handling'

module Pulse
  class Client
    include Handling

    attr_accessor :scripts

    def initialize options
      @conversations, @callbacks, @channels, @scripts = {}, {}, {}, []

      @settings   = Settings.new options
      @connection = Connection.new self, @settings

      load_scripts
      trap 2, &method(:quit)
    end

    def connect
      if not @connection.established?
        @connection.establish
      else
        raise ConnectionError, 'Connection has already been established'
      end
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

      transmit :NICK, @settings.nickname
      transmit :USER, @settings.username, ?*, ?*, @settings.realname
    end

    def connection_terminated connection
      puts "The connection was terminated."
    end

    def load_scripts
      @settings.scripts.each do |path|
        @scripts.<< Script.new path, self
      end
    end

    def unload_scripts
      @scripts.each do |script|
        script.unload!
      end.clear
    end

    def instances_of name
      @channels.values.select { |c| c.user? name }.each do |channel|
        yield channel.user name
      end
    end

    def transmit name, *args
      @connection.transmit name, *args
    end

    def say recipient, line
      transmit :PRIVMSG, recipient.to_s, line
    end

    def join channel
      transmit :JOIN, channel.to_s
    end

    def quit signal
      unload_scripts

      transmit :QUIT, "Received kill signal (#{signal})"
    end

  private

    def emit name, *args
      @callbacks[name].each do |callback|
        callback.call *args
      end if @callbacks[name]

      @scripts.each do |script|
        begin
          script.__send__ name, *args if script.respond_to? name
        rescue => exception
          puts "Script error: #{exception.message} on line #{exception.line + 1} in #{script.path}"
        end
      end
    end

    def catch name, &block
      (@callbacks[name] ||= []) << block
    end

  end
end
