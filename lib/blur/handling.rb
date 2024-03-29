# frozen_string_literal: true

module Blur
  class Client
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
    #     puts "nick: #{message.parameters[0]} user: #{message.parameters[1]} host: #{message.parameters[2]} ..."
    #   end
    #
    # @see http://www.irchelp.org/irchelp/rfc/chapter6.html
    module Handling
      # Called when the MOTD was received, which also means it is ready.
      #
      # == Callbacks:
      # Emits +:connection_ready+ with the parameter +network+.
      #
      # Automatically joins the channels specified in +:channels+.
      def got_end_of_motd(network, _message)
        emit(:connection_ready, network)

        network.channels.each_key do |channel_name|
          network.join(channel_name)
        end
      end

      # Called when the namelist of a channel was received.
      def got_name_reply(network, message)
        name  = message.parameters[2] # Channel name.
        nicks = message.parameters[3].split.map do |nick|
          # Slice the nick if the first character is a user mode prefix.
          nick.slice!(0) if network.user_prefixes.include?(nick.chr)
          nick
        end

        return unless (channel = find_or_create_channel(name, network))

        users = nicks.map { |nick| find_or_create_user(nick, network) }
        users.each do |user|
          user.channels << channel
          channel.users << user unless channel.users.include?(user)
        end

        emit(:channel_who_reply, channel)
      end

      # Called when a channel topic was changed.
      #
      # == Callbacks:
      # Emits :topic_change with the parameters +channel+ and +topic+.
      def got_channel_topic(network, message)
        _, channel_name, topic = message.parameters

        return unless (channel = find_or_create_channel(channel_name, network))

        emit(:channel_topic, channel, topic)

        channel.topic = topic
      end

      # Called when the server needs to verify that we're alive.
      def got_ping(network, message)
        network.last_pong_time = Time.now
        network.transmit(:PONG, message.parameters[0])

        emit(:network_ping, network, message.parameters[0])
      end

      # Called when the server reponds to our periodic PINGs.
      def got_pong(network, message)
        network.last_pong_time = Time.now

        emit(:network_pong, network, message.parameters[0])
      end

      # Called when a user changed nickname.
      #
      # == Callbacks:
      # Emits :user_rename with the parameters +channel+, +user+ and +new_nick+
      def got_nick(network, message)
        old_nick = message.prefix.nick

        # Update or own nickname if has been changed by the server
        if network.nickname == old_nick
          new_nick = message.parameters[0]

          emit(:nick, new_nick)
          network.nickname = new_nick
        end

        return unless (user = network.users.delete(old_nick))

        new_nick = message.parameters[0]
        emit(:user_rename, user, new_nick)
        user.nick = new_nick
        network.users[new_nick] = user
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
      def got_privmsg(network, message)
        return unless message.prefix.nick # Ignore all server privmsgs

        name, msg = message.parameters
        tags = message.tags

        if (channel = network.channels[name])
          unless (user = network.users[message.prefix.nick])
            user = User.new(message.prefix.nick, network)
          end

          user.name = message.prefix.user
          user.host = message.prefix.host

          emit(:message, user, channel, msg, tags)
        else # This is a private message
          unless (user = network.users[message.prefix.nick])
            user = User.new(message.prefix.nick, network)
            user.name = message.prefix.user
            user.host = message.prefix.host
          end

          emit(:private_message, user, msg, tags)
        end
      end

      # Called when a user joined a channel.
      #
      # == Callbacks:
      # Emits +:user_entered+ with the parameters +channel+ and +user+.
      def got_join(network, message)
        channel_name = message.parameters[0]

        user = find_or_create_user(message.prefix.nick, network)
        user.name = message.prefix.user
        user.host = message.prefix.host

        return unless (channel = find_or_create_channel(channel_name, network))

        _user_join_channel(user, channel)

        emit(:user_entered, channel, user)
      end

      # Called when a user left a channel.
      #
      # == Callbacks:
      # Emits +:user_left+ with the parameters +channel+ and +user+.
      def got_part(network, message)
        channel_name = message.parameters[0]

        return unless (channel = network.channels[channel_name])
        return unless (user = network.users[message.prefix.nick])

        _user_part_channel(user, channel)

        emit(:user_left, channel, user)
      end

      # Called when a user disconnected from a network.
      #
      # == Callbacks:
      # Emits +:user_quit+ with the parameters +channel+ and +user+.
      def got_quit(network, message)
        nick = message.prefix.nick
        reason = message.parameters[2]

        return unless (user = network.users[nick])

        user.channels.each do |channel|
          channel.users.delete(user)
        end

        emit(:user_quit, user, reason)
        network.users.delete(nick)
      end

      # Called when a user was kicked from a channel.
      #
      # == Callbacks:
      # Emits +:user_kicked+ with the parameters +kicker+, +channel+, +kickee+
      # and +reason+.
      #
      # +kicker+ is the user that kicked +kickee+.
      def got_kick network, message
        name, target, reason = message.parameters

        return unless (channel = network.channels[name])
        return unless (kicker = network.users[message.prefix.nick])
        return unless (kickee = network.users[target])

        _user_part_channel(kickee, channel)

        emit(:user_kicked, kicker, channel, kickee, reason)
      end

      # Called when a topic was changed for a channel.
      #
      # == Callbacks:
      # Emits :topic with the parameters +user+, +channel+ and +topic+.
      def got_topic(network, message)
        _channel_name, topic = message.parameters

        return unless (channel = network.channels[channel.name])

        if (user = network.users[message.prefix.nick])
          emit(:topic, user, channel, topic)
        end

        channel.topic = topic
      end

      # Called when a channel or a users flags was altered.
      #
      # == Callbacks:
      # === When it's channel modes:
      # Emits +:channel_mode+ with the parameters +channel+ and +modes+.
      # === When it's user modes:
      # Emits +:user_mode+ with the parameters +user+ and +modes+.
      def got_mode(network, message)
        name, _modes, _limit, _nick, _mask = message.parameters

        return unless (_channel = network.channels[name])
      end

      # Called when the network announces its ISUPPORT parameters.
      def got_005(network, message)
        params = message.parameters[1..-2]

        network.isupport.parse(*params)
      end

      # Received when the server supports capability negotiation.
      #
      # CAP * LS :multi-prefix sasl
      def got_cap(network, message)
        _id, command = message.parameters[0..1]

        case command
        when 'LS'
          capabilities = message.parameters[2]&.split
          req = []

          req << 'sasl' if network.sasl? && capabilities.include?('sasl')
          req << 'account-tag' if capabilities.include?('account-tag')
          req << 'account-notify' if capabilities.include?('account-notify')

          network.transmit :CAP, 'REQ', req.join(' ') if req.any?

          capabilities.each { |name| network.capabilities.push(name) }

          emit(:network_capabilities, network, capabilities)

        when 'ACK'
          capabilities = message.parameters[2]&.split

          network.transmit(:AUTHENTICATE, 'PLAIN') if capabilities&.include?('sasl') && network.sasl?

          network.cap_end if network.waiting_for_cap
        when 'NAK'
          capabilities = message.parameters[2]&.split

          if capabilities&.include?('sasl') && network.sasl?
            puts "The server does not support SASL, but you've configured it " \
              'as such! Disconnecting!'

            network.disconnect
          end
        end
      end

      def got_001(network, message)
        network.abort_cap_neg if network.waiting_for_cap

        # Get our nickname from the server
        nickname = message.parameters[0]
        network.nickname = nickname
      end

      def got_authenticate(network, message)
        case message.parameters[0]
        when '+'
          return unless network.sasl?

          sasl = network.options['sasl']

          response = "#{sasl['username']}\x00#{sasl['username']}\x00#{sasl['password']}"
          network.transmit(:AUTHENTICATE, Base64.encode64(response).strip)
        end
      end

      # :server 900 <nick> <nick>!<ident>@<host> <account> :You are now logged in as <user>
      # RPL_LOGGEDIN SASL
      def got_900(network, _message)
        network.cap_end if network.waiting_for_cap
      end

      # :server 904 <nick> :SASL authentication failed
      # ERR_SASLFAIL
      def got_904(network, message)
        _nick, _message = message.parameters

        puts 'SASL authentication failed! Disconnecting!'

        network.disconnect
      end

      def got_nickname_in_use(network, _message)
        nickname = network.options['nickname']
        network.transmit(:NICK, "#{nickname}_")
      end

      alias got_353 got_name_reply
      alias got_422 got_end_of_motd
      alias got_376 got_end_of_motd
      alias got_332 got_channel_topic
      alias got_433 got_nickname_in_use

      private

      def _user_part_channel(user, channel)
        user.channels.delete(channel)
        channel.users.delete(user)

        # Forget the user if we no longer share any channels.
        return unless user.channels.empty?

        user.network.users.delete(user.nick)
      end

      def _user_join_channel(user, channel)
        channel.users << user
        user.channels << channel
      end

      def find_or_create_user(nick, network)
        unless (user = network.users[nick])
          user = User.new(nick, network)
          network.users[nick] = user
          emit(:user_created, user)
        end

        user
      end

      def find_or_create_channel(name, network)
        unless (channel = network.channels[name])
          channel = Channel.new(name, network)
          network.channels[name] = channel
          emit(:channel_created, channel)
        end

        channel
      end
    end
  end
end
