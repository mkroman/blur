# encoding: utf-8

module Pulse
  class Client
    module Handling
      def got_376 command
        transmit :JOIN, '#maero'
      end

      def got_ping command
        transmit :PONG, command.params[0]
      end

      def got_nick command
        transmit :privmsg, '#maero', command.params.inspect
      end

      def got_privmsg command
        channel, message = command.params
        transmit :PRIVMSG, channel, message
      end
    end
  end
end
