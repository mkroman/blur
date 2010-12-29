# encoding: utf-8

require 'pulse/handling'

module Pulse
  class Client
    include Handling
    attr_reader :channels, :callbacks, :conversations, :settings, :scripts

    def initialize options
      @conversations, @callbacks, @channels, @scripts = {}, {}, {}, []

      @settings   = Settings.new options
      @connection = Connection.new self, @settings

      @networks = []

      unless options[:networks]
        raise "No networks given to the options hash", ArgumentError
      else
        options[:networks].each do |host|
          @networks.<< Network.for host
        end
      end

      load_scripts
      trap 2, &method(:quit)
    end

    def connect
      networks = @networks.select { |network| not network.connected? }

      if networks.any?
        networks.each &:connect
      else
        raise Network::ConnectionError, "Connection has already been established"
      end
    end

    def got_command command
      name = :"got_#{command.name.downcase}"
      puts "<< #{command.inspect}"

      if respond_to? name
        __send__ name, command
      end
    end

    def connection_established connection
      transmit :PASS, @settings.password if @settings.password?
      transmit :NICK, @settings.nickname
      transmit :USER, @settings.username, ?*, ?*, @settings.realname
    end

    def connection_terminated connection
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

    def each_instance_of name
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

      transmit :QUIT, "Received kill signal (#{Signal.list.invert[signal]})"
      @connection.close if @connection.established?
    end

  private

    def emit name, *args
      @callbacks[name].each do |callback|
        callback.call *args
      end if @callbacks[name]

      @scripts.each do |script|
        begin
          script.__send__ name, *args if script.respond_to? name
        rescue Exception => exception
          puts "Script error: #{exception.message} on line #{exception.line + 1} in #{script.path}"
        end
      end
    end

    def catch name, &block
      (@callbacks[name] ||= []) << block
    end

  end
end
