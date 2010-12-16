# encoding: utf-8

module Pulse
  class User
    attr_accessor :name, :user, :host, :channel

    def initialize name
      @name = name.sub /^[@|~|\+|%|&]/, ''
    end

    def synchronize sender
      @name, @user, @host = sender.nickname, sender.username, sender.hostname
    end

    def to_s; @name end
    def to_yaml opts = {}; @name.to_yaml opts end

    def inspect
      %{#<#{self.class.name} @name=#{@name.inspect} @channel=#{@channel.name.inspect}>}
    end

    alias_method :nickname, :name
  end
end
