# encoding: utf-8

module Blur
  class Network
    class User
      attr_accessor :nick, :name, :host, :modes, :channel, :network

      def self.map_mode name, character
        define_method(:"#{name}?") { @modes.include? character.to_s }
      end

      map_mode :admin,         :a
      map_mode :voice,         :v
      map_mode :owner,         :q
      map_mode :operator,      :o
      map_mode :half_operator, :h

      def initialize nick
        @nick  = nick
        @modes = ""
        
        if modes = prefix_to_mode(nick[0])
          @nick  = nick[1..-1]
          @modes = modes
        end
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
      
      def inspect
        %{#<#{self.class.name} @nick=#{@nick.inspect} @channel=#{@channel.name.inspect}>}
      end

      def to_yaml options = {}
        @nick.to_yaml options
      end
      
      def to_s
        @nick
      end

    private

      def prefix_to_mode prefix
        case prefix
        when '@' then 'o'
        when '+' then 'v'
        when '%' then 'h'
        when '&' then 'a'
        when '~' then 'q'
        end
      end
    end
  end
end
