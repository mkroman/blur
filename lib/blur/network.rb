# frozen_string_literal: true

module Blur
  # The +Network+ module is to be percieved as an IRC network.
  #
  # Although the connection is a part of the network module, it is mainly used
  # for network-related structures, such as {User}, {Channel} and {Command}.
  class Network
    include SemanticLogger::Loggable

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
    attr_reader :hostname
    # @return [String] the current nickname.
    attr_accessor :nickname
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
    # @return [Array<String>] list of capabilities supported by the network.
    attr_accessor :capabilities
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

    # Get the remote port.
    # If no port is specified, it returns 6697 if using a secure connection,
    # returns 6667 otherwise.
    #
    # @return [Fixnum] the remote port
    def port
      @port || tls? ? 6697 : 6667
    end

    # Check to see if it's a secure connection.
    def tls?
      @tls == true
    end

    # @return [Boolean] whether we want to authenticate with SASL.
    def sasl?
      @sasl && @sasl['enabled']
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
    def initialize(network_config, client)
      @isupport = ISupport.new(self)
      @capabilities = []

      @users = {}
      @client = client

      configure(network_config)
    end

    def configure(config)
      @hostname = config['hostname']
      @port = config['port']
      @nickname = config['nickname']
      @username = config['username'] || @nickname
      @realname = config['realname'] || @username
      @password = config['password']
      @tls = config['tls'] || true

      configure_sasl(config['sasl'])
      configure_channels(config['channels'])
      configure_limits(config)
    end

    def configure_limits(config)
      @reconnect_interval = 3
      @server_ping_interval_max = config.fetch('server_ping_interval',
                                               150).to_i
    end

    def configure_sasl(sasl_config)
      return unless sasl_config

      @sasl = {}

      @sasl['enabled'] = true
      @sasl['username'] = sasl_config['username']
      @sasl['password'] = sasl_config['password']
    end

    def configure_channels(channel_configs)
      @channels = {}

      channel_configs.each do |config|
        @channels[config['name']] = Channel.new(config['name'], self)
      end
    end

    # Send a message to a recipient.
    #
    # @param [String, #to_s] recipient the recipient.
    # @param [String] message the message.
    def say(recipient, message)
      transmit(:PRIVMSG, recipient.to_s, message)
    end

    # Forwards the received message to the client instance.
    #
    # Called when the network connection has enough data to form a command.
    def got_message(message)
      @client.got_message(self, message)
    end

    # Find a channel by its name.
    #
    # @param [String] name the channel name.
    # @return [Network::Channel] the matching channel, or nil.
    def channel_by_name(name)
      @channels.find { |channel| channel.name == name }
    end

    # Find all instances of channels in which there is a user with the nick
    # +nick+.
    #
    # @param [String] nick the nickname.
    # @return [Array] a list of channels in which the user is located, or nil.
    def channels_with_user(nick)
      @channels.select { |channel| channel.user_by_nick(nick) }
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
    def connect(task = Async::Task.current)
      logger.info "Connecting to #{self}"

      task.async do |subtask|
        @connection = Network::Connection.new(@hostname, @port, self, tls: @tls)
        @connection.connect(subtask)
      end
    end

    # Schedules a reconnect after a user-specified number of seconds.
    def schedule_reconnect
      raise NotImplementedError
    end

    def server_connection_timeout
      @connection.close_connection

      warn "Connection to #{self} timed out"
    end

    def periodic_ping_check
      now = Time.now
      seconds_since_pong = now - @last_pong_time

      return unless seconds_since_pong >= @server_ping_interval_max

      logger.info "No PING request from the server in #{seconds_since_pong}s!"

      transmit('PING', now.to_s)

      # Wait 15 seconds and declare a timeout if we didn't get a PONG.
      previous_pong_time = @last_pong_time.dup

      EventMachine.add_timer 15 do
        server_connection_timeout if @last_pong_time == previous_pong_time
      end
    end

    # Called when the connection was successfully established.
    def connection_established
      @waiting_for_cap = true
      @capabilities.clear

      transmit :CAP, 'LS'
      transmit :PASS, @password if @password
      transmit :NICK, @nickname
      transmit :USER, @username, 'void', 'void', @realname

      @last_pong_time = Time.now
    end

    # Called when the server doesn't support capability negotiation.
    def abort_cap_neg
      @waiting_for_cap = false

      puts 'Server does not support capability negotiation'
    end

    # Called when we're done with capability negotiation.
    def cap_end
      @waiting_for_cap = false

      transmit :CAP, 'END'
    end

    # Called when the connection was closed.
    def disconnected!
      @channels.each_value { |channel| channel.users.clear }
      @channels.clear
      @users.clear
      @ping_timer.cancel

      # @log.debug "Connection to #{self} lost!"
      @client.network_connection_closed self

      return unless @options.fetch('reconnect', DEFAULT_RECONNECT)
    end

    # Terminate the connection and clear all channels and users.
    def disconnect
      @connection.close_connection_after_writing
    end

    # Transmit a command to the server.
    #
    # @param [#to_s] command the command name.
    # @param [...] arguments all the prepended parameters.
    def transmit(command, *arguments)
      message = IRCParser::Message.new(command: command.to_s, parameters: arguments)

      if logger.trace?
        formatted_command = message.command.to_s.ljust(8, ' ')
        formatted_params = message.parameters.map(&:inspect).join(' ')

        logger.trace("→ #{formatted_command} #{formatted_params}")
      end

      @connection.send_data("#{message}\r\n")
    end

    # Send a private message.
    def send_privmsg(recipient, message)
      transmit(:PRIVMSG, recipient, message)
    end

    # Join a channel.
    def join(channel)
      transmit(:JOIN, channel)
    end

    # Convert it to a debug-friendly format.
    def to_s
      %(#<#{self.class.name} "#{hostname}":#{port}>)
    end
  end
end
