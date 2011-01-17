# encoding: utf-8

module Blur
  class Client
    module Handling

    protected
    
      # End of MOTD
      def got_end_of_motd network, command
        emit :connection_ready, network
        
        network.options[:channels].each do |channel|
          network.transmit :JOIN, channel
        end
      end
      
      # The /NAMES list
      def got_353 network, command
        name  = command[2]
        users = command[3].split.map &Network::User.method(:new)
        
        if channel = network.channel_by_name(name)
          users.each do |user|
            user.channel = channel   
            channel.users << user
          end
        else
          network.channels.<< Network::Channel.new name, network, users
        end
      end

      # The IRCd is checking whether or not we're still alive
      # PING :1285409133
      # PONG :1285409133
      def got_ping network, command
        network.transmit :PONG, command[0]
      end

=begin
      # Someone has changed their nickname
      # mk!mk@maero.dk NICK mk_
      def got_nick network, command
        each_instance_of command.sender.nickname do |user|
          emit :rename, user, command[0]
          user.name = command[0]
        end
      end
=end

      def got_privmsg network, command
        return if command.sender.is_a? String # Ignore all server privmsgs
        
        name, message = command.params
        
        if channel = network.channel_by_name(name)
          if user = channel.user_by_nick(command.sender.nickname)
            emit :message, user, channel, message
          else
            # Odd… this shouldn't happen
          end
        end
      end

=begin
      # Someone has sent a message, it can be both a private message and
      # a channel message
      # mk!mk@maero.dk PRIVMSG #maero :tp: kod
      def got_privmsg network, command
        name, message = command.params
        return unless command.sender.respond_to? :nickname

        if channel = @channels[name]
          user = channel.user command.sender.nickname
          user.synchronize command.sender
          emit :message, user, channel, message
        else
          user = User.new command.sender.nickname

          (@conversations[command.sender.nickname] ||= Conversation.new user, self).tap do |conversation|
            user.channel = conversation

            emit :conversation, user, conversation, message
          end
        end
      end


      # Someone has entered a channel.
      def got_join network, command
        if channel = @channels[command[0]]
          user = User.new command.sender.nickname
          user.channel = channel
          user.synchronize command.sender
          channel.users << user
          emit :user_entered, user, channel
        end
      end

      # Someone has left a channel.
      def got_part network, command
        if channel = @channels[command[0]]
          user = channel.user command.sender.nickname
          channel.users.delete user
          emit :user_left, user, channel
        end
      end
=end

      alias_method :got_422, :got_end_of_motd
      alias_method :got_376, :got_end_of_motd
    end
  end
end
