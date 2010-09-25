# encoding: utf-8

module Pulse
  class Client
    module Handling

  protected 
      # End of MOTD
      def got_376 command
        transmit :JOIN, '#maero'
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
        transmit :privmsg, '#maero', "#{command.sender.nickname} -> #{command[0]}"
      end

      # Someone has send a message, it can be both a private message and a channel message
      # mk!mk@maero.dk PRIVMSG #maero :tp: kod
      def got_privmsg command
        channel, message = command.params
        transmit :PRIVMSG, channel, "#{message}"
      end

    private
      def channel_with_name name
        @channels.find { |channel| channel.name == name }
      end
    end
  end
end
