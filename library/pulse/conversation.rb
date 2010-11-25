# encoding: utf-8

module Pulse
  class Conversation
    attr_accessor :id, :recipient

    def initialize recipient, client = nil
      @id, @recipient, @client = random_id, recipient, client
    end

    def say message
      @client.say @recipient.name, message
    end

    def name; @recipient.name end

    def inspect
      %{#<#{self.class.name} @recipient=#{@recipient}>}
    end

  private
    def random_id
      chars = 'abcdefghijklmnopqrstu0123456789'

      String.new.tap do |result|
        6.times { result << chars[rand chars.length] }
      end.to_sym
    end
  end
end
