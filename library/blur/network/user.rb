# encoding: utf-8

module Blur
  class Network
    class User
      attr_accessor :nick, :name, :host, :channel
      
      def initialize nick
        @nick = nick.sub /^[@|~|\+|%|&]/, ''
      end
      
      def say message
        @channel.network.say self, message
      end
      
      def inspect
        %{#<#{self.class.name} @nick=#{@nick.inspect} @channel=#{@channel.name.inspect}>}
      end
      
      def to_s
        @nick
      end
    end
  end
end