# encoding: utf-8

module Blur
  class Network
    class Channel
      attr_accessor :name, :users, :topic, :modes, :network

      def initialize name, network = nil, users = []
        @name    = name
        @users   = users
        @modes   = ""
        @network = network

        users.each { |user| user.channel = self }
      end

      def merge_modes modes
        addition = true

        modes.each_char do |char|
          case char
          when ?+
            addition = true
          when ?-
            addition = false
          else
            addition ? @modes.concat(char) : @modes.delete!(char)
          end
        end
      end

      def say message
        @network.say self, message
      end

      def user_by_nick nick
        @users.find { |user| user.nick == nick }
      end

      def inspect
        %{#<#{self.class.name} @name=#{@name.inspect} @users=#{@users.inspect}}
      end

      def to_s
        @name
      end
    end
  end
end
