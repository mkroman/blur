# frozen_string_literal: true

module Blur
  # The +Network+ module is to be percieved as an IRC network.
  #
  # Although the connection is a part of the network module, it is mainly used
  # for network-related structures, such as {User}, {Channel} and {Command}.
  class Network
    include Logging

    # +ConnectionError+ should only be triggered from within {Connection}.
    class ConnectionError < StandardError; end

    DEFAULT_PING_INTERVAL = 30
    DEFAULT_RECONNECT = true

    # Returns a unique identifier for this network.
    #
    # You can override the id in your network configuration by setting an 'id'
    # key with the id you want.. If no id is specified, the the id will be
    # constructed from the hostname and port number
    # in the format "<host>:<port>"
    #
    # @return [String] the unique identifier for this network.
    attr_reader :id
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
    # @return [Boolean] true if we're waiting for a capability negotiation.
    attr_reader :waiting_for_cap
    # @return [Time] the last time a pong was sent or received.
    attr_accessor :last_pong_time
    # The max PING interval for the server. This is used to determine when the
    # client will attempt to send its own PING command.
    #
    # @note the actual time until a client PING is sent can vary by an
    #   additional 0-30 seconds.
    # @return [Number] the max interval between pings from a server.
    attr_accessor :server_ping_interval_max

    # Check whether or not connection is established.
    def connected?
      @connection&.established?
    end

    # Get the remote hostname.
    #
    # @return [String] the remote hostname.
    def host
      @options['hostname']
    end

    # Get the remote port.
    # If no port is specified, it returns 6697 if using a secure connection,
    # returns 6667 otherwise.
    #
    # @return [Fixnum] the remote port
    def port
      @options['port'] ||= secure? ? 6697 : 6667
    end

    # Check to see if it's a secure connection.
    def secure?
      @options['secure'] == true
    end

    # @return [Boolean] whether we want to authenticate with SASL.
    def sasl?
      @options['sasl'] &&
        @options['sasl']['username'] &&
        @options['sasl']['password']
    end

    # Instantiates the network.
    #
    # @param [Hash] options The network options.
    # @option options [String] :hostname The hostname or IP-address we want to
    #   connect to.
    # @option options [String] :nickname The nickname to use.
    # @option options [optional, String] :username (Copies :nickname)
    #   The username to use. This is also known as the ident.
    # @option options [optional, String] :realname (Copies :username)
    #   The "real name" that we want to use. This is usually what shows up
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
      #@log = ::Logging.logger[self]
      @users = {}
      @channels = {}
      @isupport = ISupport.new self
      @reconnect_interval = 3
      @server_ping_interval_max = @options.fetch('server_ping_interval',
                                                 150).to_i

      unless options['nickname']
        raise ArgumentError, 'Network configuration for ' \
          "`#{id}' is missing a nickname"
      end

      @options['username'] ||= @options['nickname']
      @options['realname'] ||= @options['username']
      @options['channels'] ||= []
      @id = options.fetch 'id', "#{host}:#{port}"
    end

    # Send a message to a recipient.
    #
    # @param [String, #to_s] recipient the recipient.
    # @param [String] message the message.
    def say recipient, message
      transmit :PRIVMSG, recipient.to_s, message
    end

    # Forwards the received message to the client instance.
    #
    # Called when the network connection has enough data to form a command.
    def got_message message
      @client.got_message self, message
    rescue StandardError => exception
      puts "#{exception.class}: #{exception.message}"
      puts
      puts '---'
      puts exception.backtrace
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

    # Returns a list of user prefixes that a nick might contain.
    #
    # @return [Array<String>] a list of user prefixes.
    def user_prefixes
      isupport['PREFIX'].values
    end

    # Returns a list of user modes that also gives a users nick a prefix.
    #
    # @return [Array<String>] a list of user modes.
    def user_prefix_modes
      isupport['PREFIX'].keys
    end

    # Returns a list of channel flags (channel mode D).
    #
    # @return [Array<String>] a list of channel flags.
    def channel_flags
      isupport['CHANMODES']['D']
    end

    # Attempt to establish a connection and send initial data.
    #
    # @see Connection
    def connect
      #@log.info "Connecting to #{self}"

      begin
        @connection = EventMachine.connect host, port, Connection, self
      rescue EventMachine::ConnectionError => err
        #@log.warn "Establishing connection to #{self} failed!"
        #@log.warn err.message

        schedule_reconnect
        return
      end

      @ping_timer = EventMachine.add_periodic_timer DEFAULT_PING_INTERVAL do
        periodic_ping_check
      end
    end

    # Schedules a reconnect after a user-specified number of seconds.
    def schedule_reconnect
      #@log.info "Reconnecting to #{self} in #{@reconnect_interval} seconds"

      EventMachine.add_timer @reconnect_interval do
        connect
      end
    end

    def server_connection_timeout
      @connection.close_connection

      # @log.warn "Connection to #{self} timed out"
    end

    def periodic_ping_check
      now = Time.now
      seconds_since_pong = now - @last_pong_time

      if seconds_since_pong >= @server_ping_interval_max
        # @log.info "No PING request from the server in #{seconds_since_pong}s!"

        transmit 'PING', now.to_s

        # Wait 15 seconds and declare a timeout if we didn't get a PONG.
        previous_pong_time = @last_pong_time.dup

        EventMachine.add_timer 15 do
          if @last_pong_time == previous_pong_time
            server_connection_timeout
          else
            #@log.debug 'Received PONG from server in time. Connection is okay.'
          end
        end
      end
    end 

    # Called when the connection was successfully established.
    def connected!
      if sasl?
        @waiting_for_cap = true

        transmit :CAP, 'REQ', 'sasl'
      end

      transmit :PASS, @options['password'] if @options['password']
      transmit :NICK, @options['nickname']
      transmit :USER, @options['username'], 'void', 'void', @options['realname']

      @last_pong_time = Time.now
    end

    # Called when the server doesn't support capability negotiation.
    def abort_cap_neg
      @waiting_for_cap = false

      puts "Server does not support capability negotiation"
    end

    # Called when we're done with capability negotiation.
    def cap_end
      @waiting_for_cap = false

      transmit :CAP, 'END'
    end

    # Called when the connection was closed.
    def disconnected!
      @channels.each { |_, channel| channel.users.clear }
      @channels.clear
      @users.clear
      @ping_timer.cancel

      #@log.debug "Connection to #{self} lost!"
      @client.network_connection_closed self

      if @options.fetch('reconnect', DEFAULT_RECONNECT)
        schedule_reconnect
      end
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
      message = IRCParser::Message.new command: name.to_s, parameters: arguments

      if @client.verbose
        formatted_command = message.command.to_s.ljust 8, ' '
        formatted_params = message.parameters.map(&:inspect).join ' '
        log "#{'→' ^ :red} #{formatted_command} #{formatted_params}"
      end

      @connection.send_data "#{message}\r\n"
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
      %(#<#{self.class.name} "#{host}":#{port}>)
    end
  end
end
