# encoding: utf-8

module Blur
  class Network
    # The +Channel+ class is used for encapsulating a channel and its properties.
    #
    # Users inside the channel is stored in the {#channels} attribute.
    #
    # Modes can be set for a channel, but Blur is not 
    # {http://www.irc.org/tech_docs/005.html ISupport}-compliant yet.
    #
    # @todo make so that channels *and* users belongs to the network, and not
    #   like now where the user belongs to the channel, resulting in multiple
    #   user instances.
    class Channel
      # @return [String] the channels name.
      attr_accessor :name
      # @return [Array] a list of users in the channel.
      attr_accessor :users
      # @return [String] the channels topic.
      attr_accessor :topic
      # @return [String] all the modes set on the channel.
      attr_accessor :modes
      # @return [Network] a reference to the network.
      attr_accessor :network

      # Instantiate a user with a nickname, a network and a user list.
      def initialize name, network = nil, users = []
        @name    = name
        @users   = users
        @modes   = ""
        @network = network

        users.each { |user| user.channel = self }
      end

      # Merge the channels mode corresponding to the leading character (+ or -).
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

      # Send a message to the channel.
      #
      # @param [String] message the message to send.
      def say message
        @network.say self, message
      end

      # Find a user with +nick+ as its nickname.
      #
      # @param [String] nick the nickname to find the user of.
      def user_by_nick nick
        @users.find { |user| user.nick == nick }
      end

      # Convert it to a debug-friendly format.
      def inspect
        %{#<#{self.class.name} @name=#{@name.inspect} @users=#{@users.inspect}}
      end
      
      # Called when YAML attempts to save the object, which happens when a
      # scripts cache contains this user and the script is unloaded.
      def to_yaml options = {}
        @name.to_yaml options
      end

      # Get the channels name.
      def to_s
        @name
      end
    end
  end
end
