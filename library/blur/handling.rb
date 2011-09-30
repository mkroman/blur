# encoding: utf-8

module Blur
  class Client
    # The +Handling+ module is the very core of the IRC-part in Blur.
    #
    # When the client receives a parsed command instance, it immediately starts
    # looking for a got_(the command name) method inside the client, which
    # is implemented in this module.
    #
    # == Implementing a handler
    # Implementing a handler is very, very easy.
    #
    # All you need to do is define a method named got_(command you want to
    # implement) that accepts 2 parameters, +network+ and +command+.
    #
    # You can then do whatever you need to do with the command instance,
    # you can access the parameters of it through {Network::Command#[]}.
    #
    # Don't forget that this module is inside the clients scope, so you can
    # access all instance-variables and methods.
    #
    # @example
    #   # RPL_WHOISUSER
    #   # <nick> <user> <host> * :<real name>
    #   def got_whois_user network, command
    #     puts "nick: #{command[0]} user: #{command[1]} host: #{command[2]} …"
    #   end
    #   
    # @see http://www.irchelp.org/irchelp/rfc/chapter6.html
    module Handling
    protected
    
      # Called when the MOTD was received, which also means it is ready.
      #
      # == Callbacks:
      # Emits +:connection_ready+ with the parameter +network+.
      #
      # Automatically joins the channels specified in +:channels+.
      def got_end_of_motd network, command
        emit :connection_ready, network
        
        network.options[:channels].each do |channel|
          network.transmit :JOIN, channel
        end
      end
      
      # Called when the namelist of a channel was received.
      def got_name_reply network, command
        name  = command[2]
        users = command[3].split.map &Network::User.method(:new)
        
        if channel = network.channel_by_name(name)
          users.each do |user|
            user.channel = channel
            user.network = network

            channel.users << user
          end
        else
          channel = Network::Channel.new name, network, users

          if network.fish? and network.options[:fish].key? name
            keyphrase = network.options[:fish][name]
            channel.encryption = Encryption::FiSH.new keyphrase
          end

          network.channels << channel
        end
      end
      
      # Called when a channel topic was changed.
      #
      # == Callbacks:
      # Emits :topic_change with the parameters +channel+ and +topic+.
      def got_channel_topic network, command
        me, name, topic = command.params
        
        if channel = network.channel_by_name(name)
          emit :topic_change, channel, topic
          channel.topic = topic
        else
          channel = Network::Channel.new name, network, []
          emit :topic_change, channel, topic
          channel.topic = topic
          
          network.channels << channel
        end
      end
      
      # Called when the server needs to verify that we're alive.
      def got_ping network, command
        network.transmit :PONG, command[0]
      end
      
      # Called when a user changed nickname.
      #
      # == Callbacks:
      # Emits :user_rename with the parameters +channel+, +user+ and +nickname+ 
      # where +nickname+ is the new name.
      def got_nick network, command
        nick = command.sender.nickname
        
        if channels = network.channels_with_user(nick)
          channels.each do |channel|
            if user = channel.user_by_nick(nick)
              emit :user_rename, channel, user, command[0]
              user.nick = command[0]
            end
          end
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
      def got_privmsg network, command
        return if command.sender.is_a? String # Ignore all server privmsgs
        name, message = command.params
        
        if channel = network.channel_by_name(name)
          if user = channel.user_by_nick(command.sender.nickname)
            user.name = command.sender.username
            user.host = command.sender.hostname

            begin
              if message[0..3] == "+OK " and channel.encrypted?
                message = channel.encryption.decrypt message[4..-1]
              end
            rescue Encryption::BadInputError
              # …
            rescue => exception
              puts "-!- There was a problem with the FiSH encryption, disabling"

              channel.encryption = nil
            end
            
            emit :message, user, channel, message
          else
            # Odd… this shouldn't happen
          end
        else # This is a private message
          user = Network::User.new command.sender.nickname
          user.name = command.sender.username
          user.host = command.sender.hostname
          user.network = network

          emit :private_message, user, message
        end
      end
      
      # Called when a user joined a channel.
      #
      # == Callbacks:
      # Emits +:user_entered+ with the parameters +channel+ and +user+.
      def got_join network, command
        name = command[0]
        user = Network::User.new command.sender.nickname
        
        if channel = network.channel_by_name(name)
          user.name = command.sender.username
          user.host = command.sender.hostname
          user.channel = channel
          user.network = network
          
          channel.users << user
          
          emit :user_entered, channel, user
        end
      end
      
      # Called when a user left a channel.
      #
      # == Callbacks:
      # Emits +:user_left+ with the parameters +channel+ and +user+.
      def got_part network, command
        name = command[0]
        
        if channel = network.channel_by_name(name)
          if user = channel.user_by_nick(command.sender.nickname)
            channel.users.delete user
            
            emit :user_left, channel, user
          end
        end
      end
      
      # Called when a user disconnected from a network.
      #
      # == Callbacks:
      # Emits +:user_quit+ with the parameters +channel+ and +user+.
      def got_quit network, command
        nick = command.sender.nickname
        
        if channels = network.channels_with_user(nick)
          channels.each do |channel|
            if user = channel.user_by_nick(nick)
              channel.users.delete user 
            
              emit :user_quit, channel, user
            end
          end
        end
      end
      
      # Called when a user was kicked from a channel.
      #
      # == Callbacks:
      # Emits +:user_kicked+ with the parameters +kicker+, +channel+, +kickee+
      # and +reason+.
      #
      # +kicker+ is the user that kicked +kickee+.
      def got_kick network, command
        name, target, reason = command.params
        
        if channel = network.channel_by_name(name)
          if kicker = channel.user_by_nick(command.sender.nickname)
            if kickee = channel.user_by_nick(target)
              channel.users.delete kickee
              
              emit :user_kicked, kicker, channel, kickee, reason
            end
          end
        end
      end
      
      # Called when a topic was changed for a channel.
      #
      # == Callbacks:
      # Emits :topic with the parameters +user+, +channel+ and +topic+.
      def got_topic network, command
        name, topic = command.params
        
        if channel = network.channel_by_name(name)          
          if user = channel.user_by_nick(command.sender.nickname)
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
      def got_mode network, command
        name, modes, limit, nick, mask = command.params

        if channel = network.channel_by_name(name)
          if limit
            unless limit.numeric?
              nick = limit
            end

            if user = channel.user_by_nick(nick)
              emit :user_mode, user, modes
              user.merge_modes modes
            end
          else
            emit :channel_mode, channel, modes
            channel.merge_modes modes
          end
        end
      end

      alias_method :got_353, :got_name_reply
      alias_method :got_422, :got_end_of_motd
      alias_method :got_376, :got_end_of_motd
      alias_method :got_332, :got_channel_topic
    end
  end
end
