# encoding: utf-8

module Blur
  # The +Network+ module is to be percieved as an IRC network.
  #
  # Although the connection is a part of the network module, it is mainly used
  # for network-related structures, such as {User}, {Channel} and {Command}.
  class Network
    include Logging
    
    # +ConnectionError+ should only be triggered from within {Connection}.
    class ConnectionError < StandardError; end

    # @return [Hash] the network options.
    attr_accessor :options

    # @return [Hash] the map of users that is known.
    attr_accessor :users
    # @return [Hash] the map of channels the client is in.
    attr_accessor :channels
    # @return [Client] the client reference.
    attr_accessor :client
    # @return [Network::Connection] the connection instance.
    attr_accessor :connection
    # @return [Network::ISupport] the network isupport specs.
    attr_accessor :isupport

    # Check whether or not connection is established.
    def connected?; @connection and @connection.established? end

    # Get the remote hostname.
    #
    # @return [String] the remote hostname.
    def host; @options['hostname'] end

    # Get the remote port.
    # If no port is specified, it returns 6697 if using a secure connection,
    # returns 6667 otherwise.
    #
    # @return [Fixnum] the remote port
    def port; @options['port'] ||= secure? ? 6697 : 6667 end
    
    # Check to see if it's a secure connection.
    def secure?; @options['secure'] == true end

    # Instantiates the network.
    #
    # @param [Hash] options The network options.
    # @option options [String] :hostname The hostname or IP-address we want to
    #   connect to.
    # @option options [String] :nickname The nickname to use.
    # @option options [optional, String] :username (Copies :nickname)
    #   The username to use. This is also known as the ident.
    # @option options [optional, String] :realname (Copies :username)
    #   The “real name” that we want to use. This is usually what shows up
    #   as "Name" when you whois a user.
    # @option options [optional, String] :password The password for the network.
    #   This is sometimes needed for private networks.
    # @option options [optional, Fixnum] :port (6697 if ssl, otherwise 6667) 
    #   The remote port we want to connect to.
    # @option options [optional, Boolean] :secure Set whether this is a secure
    #   (SSL-encrypted) connection.
    # @option options [optional, String] :ssl_cert_file Local path of a
    #   readable file that contains a X509 CA certificate to validate against.
    # @option options [optional, String] :ssl_fingerprint Validate that the 
    #   remote certificate matches the specified fingerprint.
    # @option options [optional, Boolean] :ssl_no_verify Disable verification
    #   alltogether.
    def initialize options, client = nil
      @client = client
      @options = options
      @users = {}
      @channels = {}
      @isupport = ISupport.new self
      
      unless options['nickname']
        if options['hostname']
          raise ArgumentError, "Network configuration for `#{options['hostname']}' is missing a nickname"
        else
          raise ArgumentError, "Network configuration is missing a nickname"
        end
      end
      
      @options['username'] ||= @options['nickname']
      @options['realname'] ||= @options['username']
      @options['channels'] ||= []
    end
    
    # Send a message to a recipient.
    #
    # @param [String, #to_s] recipient the recipient.
    # @param [String] message the message.
    def say recipient, message
      transmit :PRIVMSG, recipient.to_s, message
    end
    
    # Called when the network connection has enough data to form a command.
    def got_command command
      @client.got_command self, command
    rescue => e
      puts "#{e.class}: #{e.message}"
      puts
      puts "---"
      puts e.backtrace
    end
    
    # Find a channel by its name.
    #
    # @param [String] name the channel name.
    # @return [Network::Channel] the matching channel, or nil.
    def channel_by_name name
      @channels.find {|channel| channel.name == name }
    end
    
    # Find all instances of channels in which there is a user with the nick
    # +nick+.
    #
    # @param [String] nick the nickname.
    # @return [Array] a list of channels in which the user is located, or nil.
    def channels_with_user nick
      @channels.select {|channel| channel.user_by_nick nick }
    end

    # Returns a list of user prefixes that a nick might contain.
    #
    # @return [Array<String>] a list of user prefixes.
    def user_prefixes
      isupport["PREFIX"].values
    end

    # Returns a list of user modes that also gives a users nick a prefix.
    #
    # @return [Array<String>] a list of user modes.
    def user_prefix_modes
      isupport["PREFIX"].keys
    end

    # Returns a list of channel flags (channel mode D).
    #
    # @return [Array<String>] a list of channel flags.
    def channel_flags
      isupport["CHANMODES"]["D"]
    end

    # Attempt to establish a connection and send initial data.
    #
    # @see Connection
    def connect
      @connection = EventMachine.connect host, port, Connection, self
    end

    # Called when the connection was successfully established.
    def connected!
      transmit :PASS, @options['password'] if @options['password']
      transmit :NICK, @options['nickname']
      transmit :USER, @options['username'], :void, :void, @options['realname']
    end

    # Called when the connection was closed.
    def disconnected!
      @channels.each {|name, channel| channel.users.clear }
      @channels.clear
      @users.clear

      @client.network_connection_closed self
    end
    
    # Terminate the connection and clear all channels and users.
    def disconnect
      @connection.close_connection_after_writing
    end
    
    # Transmit a command to the server.
    #
    # @param [Symbol, String] name the command name.
    # @param [...] arguments all the prepended parameters.
    def transmit name, *arguments
      command = Command.new name, arguments

      if @client.verbose
        log "#{'→' ^ :red} #{command.name.to_s.ljust(8, ' ') ^ :light_gray} #{command.params.map(&:inspect).join ' '}"
      end
      
      @connection.send_data "#{command}\r\n"
    end

    # Send a private message.
    def send_privmsg recipient, message
      transmit :PRIVMSG, recipient, message
    end

    # Join a channel.
    def join channel
      transmit :JOIN, channel
    end

    # Convert it to a debug-friendly format.
    def to_s
      %{#<#{self.class.name} "#{host}":#{port}>}
    end
  end
end
