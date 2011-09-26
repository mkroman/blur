# encoding: utf-8

module Blur
  class Network
    # The +User+ class is used for encapsulating a user and its properties.
    #
    # The user owns a reference to its parent channel.
    #
    # Modes can be set for a user, but Blur is not 
    # {http://www.irc.org/tech_docs/005.html ISupport}-compliant yet.
    #
    # @todo make so that channels *and* users belongs to the network, and not
    #   like now where the user belongs to the channel, resulting in multiple
    #   user instances.
    class User
      # @return [String] the users nickname.
      attr_accessor :nick
      # @return [String] the users username.
      attr_accessor :name
      # @return [String] the users hostname.
      attr_accessor :host
      # @return [String] all the modes set on the user.
      attr_accessor :modes
      # @return [Channel] a reference to the users channel.
      attr_accessor :channel
      # @return [Network] a reference to the network.
      attr_accessor :network

      # Check to see if the user is an admin (+a)
      def admin?; @modes.include? "a" end
      # Check to see if the user has voice (+v)
      def voice?; @modes.include? "v" end
      # Check to see if the user is the owner (+q)
      def owner?; @modes.include? "q" end
      # Check to see if the user is an operator (+o)
      def operator?; @modes.include? "o" end
      # Check to see if the user is an half-operator (+h)
      def half_operator?; @modes.include? "h" end

      # Instantiate a user with a nickname.
      def initialize nick
        @nick  = nick
        @modes = ""
        
        if modes = prefix_to_mode(nick[0])
          @nick  = nick[1..-1]
          @modes = modes
        end
      end

      # Merge the users mode corresponding to the leading character (+ or -).
      #
      # @param [String] modes the modes to merge with.
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
      
      # Send a private message to the user.
      #
      # @param [String] message the message to send.
      def say message
        @network.say self, message
      end
      
      # Convert it to a debug-friendly format.
      def inspect
        %{#<#{self.class.name} @nick=#{@nick.inspect} @channel=#{@channel.name.inspect}>}
      end

      # Called when YAML attempts to save the object, which happens when a
      # scripts cache contains this user and the script is unloaded.
      def to_yaml options = {}
        @nick.to_yaml options
      end
      
      # Get the users nickname.
      def to_s
        @nick
      end

    private

      # Translate a nickname-prefix to a mode character.
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
