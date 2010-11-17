# encoding: utf-8

module Pulse
  class User
    attr_accessor :name, :user, :host, :channel

    def initialize name
      @name = name.sub /^\W/, ''
    end

    def synchronize sender
      @name = sender.nickname
      @user = sender.username
      @host = sender.hostname
    end

    def to_s; @name end

    def inspect
      %{#<#{self.class.name} @name=#{@name.inspect} @channel=#{@channel.name.inspect}>}
    end
  end
end
