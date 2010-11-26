# encoding: utf-8

require 'pulse/handling'

module Pulse
  class Client
    include Handling

    attr_accessor :scripts

    def initialize options
      @scripts       = []
      @channels      = {}
      @settings      = Settings.new options
      @callbacks     = {}
      @connection    = Connection.new self, @settings
      @conversations = {}

      load_scripts
    end

    def connect
      trap 2 do
        unload_scripts
        @connection.close
        Thread.list.each &:kill
        transmit :QUIT, "I was interrupted" 
      end
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

      transmit :NICK, @settings.nickname
      transmit :USER, @settings.username, ?*, ?*, @settings.realname
    end

    def connection_terminated connection
      puts "The connection was terminated."
    end

    def say recipient, line
      transmit :PRIVMSG, recipient.to_s, line
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

    def each_user name
      @channels.values.select { |c| c.user? name }.each do |channel|
        yield channel.user name
      end
    end

    def send_file path, recipient
      Thread.new path, recipient do
        DCC.new(path).listen do |addr|
          # FIXME: find the right local ip address and convert it to an integer
          transmit :PRIVMSG, recipient, "\x01DCC SEND #{File.basename path} 1489377357 #{addr[1]} #{File.size path}\x01"
        end
      end
    end

  private

    def emit name, *args
      @callbacks[name].each do |callback|
        callback.call *args
      end if @callbacks[name]


      begin
        @scripts.each do |script|
          if script.respond_to? name
            script.__send__ name, *args
          end
        end
      rescue
        puts "Script error #$!"
      end
    end

    def catch name, &block
      (@callbacks[name] ||= []) << block
    end

    def transmit name, *args
      @connection.transmit name, *args
    end
  end
end
