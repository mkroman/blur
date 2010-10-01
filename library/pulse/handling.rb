# encoding: utf-8

module Pulse
  class Client
    module Handling

  protected 
      # End of MOTD
      def got_376 command
        transmit :JOIN, '#maero'
      end

      # The /NAMES list
      def got_353 command
        users = command[3].split.map &User.method(:new)
        @channels[command[2]] ||= Channel.new(command[2], users)
      end

      # End of /NAMES list
      def got_366 command
        
      end

      # The IRCd is checking whether or not we're still alive
      # PING :1285409133
      # PONG :1285409133
      def got_ping command
        transmit :PONG, command[0]
      end

      # Someone has changed their nickname
      # mk!mk@maero.dk NICK mk_
      def got_nick command
        each_user command.sender.nickname do |user|
          emit :nickchange, user, command[0]
          user.name = command[0]
        end
      end

      # Someone has send a message, it can be both a private message and a channel message
      # mk!mk@maero.dk PRIVMSG #maero :tp: kod
      def got_privmsg command
        channel, message = command.params
        transmit :PRIVMSG, channel, "#{@channels[channel]}"
      end
    end
  end
end
