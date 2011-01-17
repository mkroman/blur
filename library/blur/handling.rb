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
      
      def got_part network, command
        name = command[0]
        
        if channel = network.channel_by_name(name)
          if user = channel.user_by_nick(command.sender.nickname)
            channel.users.delete user
            
            emit :user_left, channel, user
          end
        end
      end
      
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
