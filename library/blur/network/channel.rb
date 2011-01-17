# encoding: utf-8

module Blur
  class Network
    class Channel
      attr_accessor :name, :users, :network

      def initialize name, network = nil, users = []
        @name    = name
        @users   = users
        @network = network

        users.each { |user| user.channel = self }
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