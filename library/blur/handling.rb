# frozen_string_literal: true

module Blur
  # The +Handling+ module is the very core of the IRC-part in Blur.
  #
  # When the client receives a parsed message instance, it immediately starts
  # looking for a got_(the message name) method inside the client, which
  # is implemented in this module.
  #
  # == Implementing a handler
  # Implementing a handler is very, very easy.
  #
  # All you need to do is define a method named got_(message you want to
  # implement) that accepts 2 parameters, +network+ and +message+.
  #
  # You can then do whatever you need to do with the message instance,
  # you can access the parameters of it through {Network::message#[]}.
  #
  # Don't forget that this module is inside the clients scope, so you can
  # access all instance-variables and methods.
  #
  # @example
  #   # RPL_WHOISUSER
  #   # <nick> <user> <host> * :<real name>
  #   def got_whois_user network, message
  #     puts "nick: #{message.parameters[0]} user: #{message.parameters[1]} host: #{message.parameters[2]} …"
  #   end
  #
  # @see http://www.irchelp.org/irchelp/rfc/chapter6.html
  module Handling
    HANDLERS = {
      'PRIVMSG' => :handle_privmsg,
      'TOPIC' => :handle_topic,
      'PING' => :handle_ping,
      'PONG' => :handle_pong,
      'NICK' => :handle_nick,
      'JOIN' => :handle_join,
      'PART' => :handle_part,
      'QUIT' => :handle_quit,
      'KICK' => :handle_kick,
      'MODE' => :handle_mode,

      'CAP' => :handle_cap,

      # SASL ATHENTICATE
      'AUTHENTICATE' => :handle_sasl_authenticate,

      # 001 RPL_WELCOME (RFC2812)
      '001' => :handle_welcome,

      # 005 RPL_ISUPPORT
      '005' => :handle_isupport,

      # 332 RPL_TOPIC (RFC1459)
      '332' => :handle_channel_topic,
      # 353 RPL_NAMREPLY (RFC1459)
      '353' => :handle_name_reply,

      # 900 RPL_LOGGEDIN (IRCv3.1)
      '900' => :handle_sasl_logged_in,
      # 904 ERR_SASLFAIL (IRCv3.1)
      '904' => :handle_sasl_fail,
      # 901 RPL_LOGGEDOUT
      # 902 ERR_NICKLOCKED
      # 903 RPL_SASLSUCCESS
      # 905 ERR_SASLTOOLONG
      # 906 ERR_SASLABORTED
      # 907 ERR_SASLALREADY
      # 908 RPL_SASLMECHS
    }

    # Called when the MOTD was received, which also means it is ready.
    #
    # == Callbacks:
    # Emits +:connection_ready+ with the parameter +network+.
    #
    # Automatically joins the channels specified in +:channels+.
    def handle_welcome message
      if waiting_for_cap
        abort_cap_neg
      end

      emit :connection_ready

      @options['channels'].each do |channel|
        join channel
      end
    end

    # Called when the namelist of a channel was received.
    def handle_name_reply message
      name  = message.parameters[2] # Channel name.
      nicks = message.parameters[3].split.map do |nick|
        # Slice the nick if the first character is a user mode prefix.
        if user_prefixes.include? nick.chr
          nick.slice! 0
        end

        nick
      end

      if channel = find_or_create_channel(name)
        users = nicks.map{|nick| find_or_create_user nick }
        users.each do |user|
          user.channels << channel
          channel.users << user unless channel.users.include? user
        end

        emit :channel_who_reply, channel
      end
    end

    # Called when a channel topic was changed.
    #
    # == Callbacks:
    # Emits :topic_change with the parameters +channel+ and +topic+.
    def handle_topic message
      _, channel_name, topic = message.parameters

      if channel = find_or_create_channel(channel_name)
        emit :channel_topic, channel, topic

        channel.topic = topic
      end
    end

    # Called when the server needs to verify that we're alive.
    def handle_ping message
      @last_pong_time = Time.now
      transmit :PONG, message.parameters[0]

      emit :network_ping, message.parameters[0]
    end

    # Called when the server reponds to our periodic PINGs.
    def handle_pong message
      @last_pong_time = Time.now

      emit :network_pong, message.parameters[0]
    end

    # Called when a user changed nickname.
    #
    # == Callbacks:
    # Emits :user_rename with the parameters +channel+, +user+ and +new_nick+
    def handle_nick message
      old_nick = message.prefix.nick
      
      if user = @users.delete(old_nick)
        new_nick = message.parameters[0]
        emit :user_rename, user, new_nick
        user.nick = new_nick
        @users[new_nick] = user
      end
    end

    # Called when a message was received (both channel and private messages).
    #
    # == Callbacks:
    # === When it's a channel message:
    # Emits +:message+ with the parameters +user+, +channel+ and +message+.
    # === When it's a private message:
    # Emits +:private_message+ with the parameters +user+ and +message+.
    #
    # @note Messages are contained as strings.
    def handle_privmsg message
      return unless message.prefix.nick # Ignore all server privmsgs
      name, msg = message.parameters

      if channel = @channels[name]
        unless user = @users[message.prefix.nick]
          user = User.new message.prefix.nick, self
        end

        user.name = message.prefix.user
        user.host = message.prefix.host

        emit :message, user, channel, msg
      else # This is a private message
        unless user = @users[message.prefix.nick]
          user = User.new message.prefix.nick, self
          user.name = message.prefix.user
          user.host = message.prefix.host
        end

        emit :private_message, user, msg
      end
    end

    # Called when a user joined a channel.
    #
    # == Callbacks:
    # Emits +:user_entered+ with the parameters +channel+ and +user+.
    def handle_join message
      channel_name = message.parameters[0]

      user = find_or_create_user message.prefix.nick
      user.name = message.prefix.user
      user.host = message.prefix.host
      
      if channel = find_or_create_channel(channel_name)
        _user_join_channel user, channel

        emit :user_entered, channel, user
      end
    end

    # Called when a user left a channel.
    #
    # == Callbacks:
    # Emits +:user_left+ with the parameters +channel+ and +user+.
    def handle_part message
      channel_name = message.parameters[0]
      
      if channel = @channels[channel_name]
        if user = @users[message.prefix.nick]
          _user_part_channel user, channel

          emit :user_left, channel, user
        end
      end
    end

    # Called when a user disconnected from a network.
    #
    # == Callbacks:
    # Emits +:user_quit+ with the parameters +channel+ and +user+.
    def handle_quit message
      nick = message.prefix.nick
      reason = message.parameters[2]

      if user = @users[nick]
        user.channels.each do |channel|
          channel.users.delete user
        end

        emit :user_quit, user, reason
        @users.delete nick
      end
    end

    # Called when a user was kicked from a channel.
    #
    # == Callbacks:
    # Emits +:user_kicked+ with the parameters +kicker+, +channel+, +kickee+
    # and +reason+.
    #
    # +kicker+ is the user that kicked +kickee+.
    def handle_kick message
      name, target, reason = message.parameters

      if channel = @channels[name]
        if kicker = @users[message.prefix.nick]
          if kickee = @users[target]
            _user_part_channel kickee, channel

            emit :user_kicked, kicker, channel, kickee, reason
          end
        end
      end
    end

    # Called when a topic was changed for a channel.
    #
    # == Callbacks:
    # Emits :topic with the parameters +user+, +channel+ and +topic+.
    def handle_topic message
      channel_name, topic = message.parameters

      if channel = @channels[channel_name]
        if user = @users[message.prefix.nick]
          emit :topic, user, channel, topic
        end

        channel.topic = topic
      end
    end

    # Called when a channel or a users flags was altered.
    #
    # == Callbacks:
    # === When it's channel modes:
    # Emits +:channel_mode+ with the parameters +channel+ and +modes+.
    # === When it's user modes:
    # Emits +:user_mode+ with the parameters +user+ and +modes+.
    def handle_mode message
      name, modes, limit, nick, mask = message.parameters

      if channel = @channels[name]
        # FIXME
      end
    end

    # Called when the network announces its ISUPPORT parameters.
    def handle_isupport message
      params = message.parameters[1..-2]

      @isupport.parse *params
    end

    # Received when the server supports capability negotiation.
    #
    # CAP * LS :multi-prefix sasl
    def handle_cap message
      _id, command = message.parameters[0..1]

      case command
      when 'LS'
        capabilities = message.parameters[2]&.split

        if capabilities.include?('sasl') && sasl?
          transmit :AUTHENTICATE, 'PLAIN'
        else
          transmit :CAP, 'END'
        end

        capabilities.each{|name| @capabilities.push name }

        emit :network_capabilities, capabilities

      when 'ACK'
        capabilities = message.parameters[2]&.split

        if capabilities&.include? 'sasl' && sasl?
          transmit :AUTHENTICATE, 'PLAIN'
        else
          cap_end
        end

      when 'NAK'
        capabilities = message.parameters[2]&.split

        if capabilities&.include? 'sasl' && sasl?
          puts "The server does not support SASL, but you've configured it " \
            "as such! Disconnecting!"

          disconnect
        end
      end
    end

    def handle_sasl_authenticate message
      case message.parameters[0]
      when '+'
        return unless sasl?
        sasl = @options['sasl']

        response = "#{sasl['username']}\x00#{sasl['username']}\x00#{sasl['password']}"
        transmit :AUTHENTICATE, Base64.encode64(response).strip
      end
    end

    # :server 900 <nick> <nick>!<ident>@<host> <account> :You are now logged in as <user>
    # RPL_LOGGEDIN SASL
    def handle_sasl_logged_in message
      if waiting_for_cap
        cap_end
      end
    end

    # :server 904 <nick> :SASL authentication failed
    # ERR_SASLFAIL
    def handle_sasl_fail message
      nick, message = message.parameters

      puts 'SASL authentication failed! Disconnecting!'

      disconnect
    end

  private

    def _user_part_channel user, channel
      user.channels.delete channel
      channel.users.delete user

      # Forget the user if we no longer share any channels.
      if user.channels.empty?
        user.network.users.delete user.nick
      end
    end

    def _user_join_channel user, channel
      channel.users << user
      user.channels << channel
    end

    def find_or_create_user nick
      unless user = @users[nick]
        user = User.new nick, self
        @users[nick] = user
        emit :user_created, user
      end

      user
    end

    def find_or_create_channel name
      unless channel = @channels[name]
        channel = Channel.new name, self
        @channels[name] = channel
        emit :channel_created, channel
      end

      channel
    end
  end
end
