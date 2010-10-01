# encoding: utf-8

module Pulse
  class Channel
    attr_accessor :name, :users

    def initialize name, users = []
      @name, @users = name, users

      users.each { |user| user.channel = self }
    end

    def user name; @users.find { |user| user.name == name } end
    def user? name; not user(name).nil? end

    def to_s
      %{#<#{self.class.name} @name=#{@name.inspect} @users=#{@users.inspect}}
    end
  end
end
