# encoding: utf-8

module Blur
  class Script < Module
    # The +Fantasy+ module is a module that gives the ability to turn a
    # script into a DSL-like framework.
    #
    # What it does is automatically test to see if a message starts with a
    # trigger, and then, if so, it sends the command-part of the message to
    # the script object itself.
    #
    # This way, the plugin-writer doesn't need to have repetetive code like
    # that in every script.
    #
    # @example
    #   Script :example do
    #     include Fantasy
    #
    #     def command_test user, channel, message
    #       channel.say "I hear you."
    #     end
    #   end
    #
    #   # And if a user were to send the message ".test my method", it would
    #   # trigger the #command_test method with the following arguments
    #   #
    #   # user    => #<Blur::Network::User … >
    #   # channel => #<Blur::Network::Channel … >
    #   # message => ".test my method"
    module Fantasy
      # The prefix that turns it into a possible command.
      MessageTrigger = "."

      # Extend +klass+ with self.
      def self.included klass
        klass.extend self
      end

      # Called when a script has been loaded, for use in modules extending
      # the script.
      def module_init
        @__fantasy_triggers = []

        public_methods.grep(/^command_/).each do |trigger|
          @__fantasy_triggers << trigger.to_s[8..-1]
        end
      end
      
      # Handle all calls to the scripts +message+ method, check to see if
      # the message containts a valid command, serialize it and pass it to
      # the script as command_name with the parameters +user+, +channel+
      # and +message+.
      def message user, channel, line
        return unless line.start_with? MessageTrigger
        
        command, args = line.split $;, 2
        trigger = serialize command

        if @__fantasy_triggers.include? trigger
          __send__ :"command_#{trigger}", user, channel, args
        end
      end
      
    protected
      
      # Strip all non-word characters from the input command.
      def serialize name
        name.gsub /\W/, '' if name
      end
    end
  end
end
