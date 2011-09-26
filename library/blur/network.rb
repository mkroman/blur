# encoding: utf-8

module Blur
  # The +Network+ module is to be percieved as an IRC network.
  #
  # Although the connection is a part of the network module, it is mainly used
  # for network-related structures, such as {User}, {Channel} and {Command}.
  class Network
    # +ConnectionError+ should only be triggered from within {Connection}.
    class ConnectionError < StandardError; end

    # @return [Hash] the network options.
    attr_accessor :options
    # @return [Array] the list of channels the client is in.
    attr_accessor :channels
    # @return [Array] the list of private messages the client remembers.
    attr_accessor :dialogues
    # @return [Client] the client delegate.
    attr_accessor :delegate
    # @return [Network::Connection] the connection instance.
    attr_accessor :connection

    # Check whether or not connection is established.
    def connected?; @connection.established? end

    # Get the remote hostname.
    #
    # @return [String] the remote hostname.
    def host; @options[:hostname] end

    # Get the remote port.
    # If no port is specified, it returns 6697 if using a secure connection,
    # returns 6667 otherwise.
    #
    # @return [Fixnum] the remote port
    def port; @options[:port] ||= secure? ? 6697 : 6667 end
    
    # Check to see if it's a secure connection.
    def secure?; @options[:secure] == true end

    # Instantiates the network.
    #
    # @param [Hash] options the network options.
    # @option options [String] :hostname the remote hostname.
    # @option options [String] :nickname the nickname to represent.
    # @option options [optional, String] :username the username to represent.
    # @option options [optional, String] :realname the “real name” to represent.
    # @option options [optional, String] :password the password for the network.
    # @option options [optional, Fixnum] :port the remote port.
    # @option options [optional, Boolean] :secure use a secure connection.
    def initialize options
      @options  = options
      @channels = []
      
      unless options[:nickname]
        raise ArgumentError, "nickname is missing from the networks option block"
      end
      
      @options[:username] ||= @options[:nickname]
      @options[:realname] ||= @options[:username]
      @options[:channels] ||= []

      @connection = Connection.new self, host, port
    end
    
    # Send a message to a recipient.
    #
    # @param [String, #to_s] recipient the recipient.
    # @param [String] message the message.
    def say recipient, message
      transmit :PRIVMSG, recipient, message
    end
    
    # Called when the network connection has enough data to form a command.
    def got_command command
      @delegate.got_command self, command
    end
    
    # Find a channel by its name.
    #
    # @param [String] name the channel name.
    # @return [Network::Channel] the matching channel, or nil.
    def channel_by_name name
      @channels.find { |channel| channel.name == name }
    end
    
    # Find all instances of channels in which there is a user with the nick
    # +nick+.
    #
    # @param [String] nick the nickname.
    # @return [Array] a list of channels in which the user is located, or nil.
    def channels_with_user nick
      @channels.select { |channel| channel.user_by_nick nick }
    end

    # Attempt to establish a connection and send initial data.
    #
    # @see Connection
    def connect
      @connection.establish
      @connection.enable_ssl OpenSSL::SSL::VERIFY_NONE if secure?
      
      transmit :PASS, @options[:password] if @options[:password]
      transmit :NICK, @options[:nickname]
      transmit :USER, @options[:username], :void, :void, @options[:realname]
    end
    
    # Terminate the connection and clear all channels and users.
    def disconnect
      @connection.terminate

      @channels.each { |channel| channel.users.clear }
      @channels.clear
    end
    
    # Transmit a command to the server.
    #
    # @param [Symbol, String] name the command name.
    # @param [...] arguments all the prepended parameters.
    def transmit name, *arguments
      command = Command.new name, arguments
      puts "-> #{inspect ^ :bold} | #{command}"
      
      @connection.transmit command
    end
    
    # Tell the connection to transcieve.
    #
    # @see Connection#transcieve
    def transcieve; @connection.transcieve end
    
    # Convert it to a debug-friendly format.
    def to_s
      %{#<#{self.class.name} "#{host}":#{port}>}
    end
  end
end
