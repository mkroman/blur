# frozen_string_literal: true

module Blur
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
    # @return [String] the channels topic.
    attr_accessor :topic
    # @return [Array] list of references to users in the channel.
    attr_accessor :users
    # @return [String] all the modes set on the channel.
    attr_accessor :modes
    # @return [Network] a reference to the network.
    attr_accessor :network

    # Instantiate a user with a nickname, a network and a user list.
    def initialize(name, network = nil)
      @name    = name
      @users   = []
      @modes   = ''
      @network = network
    end

    # Merge the channels mode corresponding to the leading character (+ or -).
    #
    # @param [String] modes the modes to merge with.
    def merge_modes(modes)
      addition = true

      modes.each_char do |char|
        case char
        when '+' then addition = true
        when '-' then addition = false
        else
          addition ? @modes.concat(char) : @modes.delete!(char)
        end
      end
    end

    # Send a message to the channel.
    #
    # @param [String] message the message to send.
    def say(message)
      @network.say(self, message)
    end

    # Convert it to a debug-friendly format.
    def inspect
      "#<#{self.class.name}:0x#{object_id.to_s 16} " \
        "@name=#{@name.inspect} " \
        "@topic=#{@topic.inspect} " \
        "@users=#{@users.inspect}>"
    end

    # Called when YAML attempts to save the object, which happens when a
    # scripts cache contains this user and the script is unloaded.
    def to_yaml(options = {})
      @name.to_yaml(options)
    end

    # Get the channels name.
    def to_s
      @name
    end
  end
end
