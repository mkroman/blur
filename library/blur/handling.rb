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
      
      # Are we still breathing?
      def got_ping network, command
        network.transmit :PONG, command[0]
      end
      
      # Someone changed their nickname
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
      
      # Someone send a message
      def got_privmsg network, command
        return if command.sender.is_a? String # Ignore all server privmsgs
        name, message = command.params
        
        if channel = network.channel_by_name(name)
          if user = channel.user_by_nick(command.sender.nickname)
            user.name = command.sender.username
            user.host = command.sender.hostname
            
            emit :message, user, channel, message
          else
            # Odd… this shouldn't happen
          end
        end
      end
      
      # Someone joined a channel
      def got_join network, command
        name = command[0]
        user = Network::User.new command.sender.nickname
        
        if channel = network.channel_by_name(name)
          user.name = command.sender.username
          user.host = command.sender.hostname
          
          channel.users << user
          
          emit :user_entered, channel, user
        end
      end
      
      # Someone left a channel
      def got_part network, command
        name = command[0]
        
        if channel = network.channel_by_name(name)
          if user = channel.user_by_nick(command.sender.nickname)
            channel.users.delete user
            
            emit :user_left, channel, user
          end
        end
      end
      
      # Someone quit irc
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

      alias_method :got_422, :got_end_of_motd
      alias_method :got_376, :got_end_of_motd
    end
  end
end
