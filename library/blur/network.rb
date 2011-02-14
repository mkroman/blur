# encoding: utf-8

module Blur
  class Network
    class ConnectionError < StandardError; end

    attr_accessor :options, :channels, :delegate, :connection

    def connected?; @connection.established? end

    def host
      @options[:hostname]
    end

    def port
      @options[:port] ||= secure? ? 6697 : 6667
    end
    
    def secure?
      @options[:secure] == true
    end

    def initialize options = {}
      @options  = options
      @channels = []
      
      unless options[:nickname]
        raise ArgumentError, "nickname is missing from the network's option block"
      end
      
      @options[:username] ||= @options[:nickname]
      @options[:realname] ||= @options[:username]
      @options[:channels] ||= []

      @connection = Connection.new self, host, port
    end
    
    def say recipient, message
      transmit :PRIVMSG, recipient, message
    end
    
    def got_command command
      @delegate.got_command self, command
    end
    
    def channel_by_name name
      @channels.find { |channel| channel.name == name }
    end
    
    def channels_with_user nick
      @channels.select { |channel| channel.user_by_nick nick }
    end

    def connect
      @connection.establish
      @connection.enable_ssl OpenSSL::SSL::VERIFY_NONE if secure?
      
      transmit :PASS, @options[:password] if @options[:password]
      transmit :NICK, @options[:nickname]
      transmit :USER, @options[:username], :void, :void, @options[:realname]
    end
    
    def disconnect
      @connection.terminate

      @channels.each { |channel| channel.users.clear }
      @channels.clear
    end
    
    def transmit name, *arguments
      command = Command.new name, arguments
      puts "-> #{inspect ^ :bold} | #{command}"
      
      @connection.transmit command
    end
    
    def transcieve
      @connection.transcieve
    end
    
    def to_s
      %{#<#{self.class.name} "#{host}":#{port}>}
    end
  end
end
