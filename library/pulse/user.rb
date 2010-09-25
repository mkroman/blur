# encoding: utf-8

module Pulse
  class User
    attr_accessor :name, :channel

    def initialize name
      @name = name.gsub /^\W/, ''
    end

    def to_s
      %{#<#{self.class.name} @name=#{@name.inspect} @channel=#{@channel.name}>}
    end
  end
end
