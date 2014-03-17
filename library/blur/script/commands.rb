# encoding: utf-8

module Blur
  class Script
    # The +Commands+ module is a module that gives the ability to turn a
    # script into a DSL-like framework.
    module Commands
      class Command
        DefaultOptions = { prefix: '.', hostmask: nil }

        def initialize triggers, options = {}, &block
          @triggers = Array === triggers ? triggers : [triggers]
          @options = DefaultOptions.merge options
          @block = block
        end

        # Called by the Commands module.
        #
        # Calls the command block if the trigger matches the criteria.
        def received_message user, channel, message
          prefix = @options[:prefix]

          # Return if the prefix don't match.
          return unless message.start_with? prefix

          # Return if the hostmask don't match.
          # FIXME: Maybe use globbing instead of regular expressions?
          unless @options[:hostmask].nil?
            hostmask = "#{user.nick}!#{user.name}@#{user.host}"

            return unless hostmask =~ @options[:hostmask]
          end

          command, args = split_message message

          # Strip the prefix and compare the trigger name.
          if self.matches_trigger? command
            @block.call user, channel, args
          end
        end

      protected

        def split_message message
          prefix = @options[:prefix]
          command, args = message[prefix.length..-1].split $;, 2

          return command, args
        end

        def matches_trigger? command
          return @triggers.find{|trigger| trigger.to_s == command }
        end
      end

      # Extend +base+ with self.
      def self.extended base
        base.instance_variable_set :@__commands, []

        p base.instance_variables
      end

      # Add a new command handler and trigger.
      def command name, *args, &block
        @__commands << Command.new(name, *args, &block)
      end
      
      # Handle all calls to the scripts +message+ method, check to see if
      # the message containts a valid command, serialize it and pass it to
      # the script as command_name with the parameters +user+, +channel+
      # and +message+.
      def message user, channel, line
        @__commands.each do |command|
          command.received_message user, channel, line
        end
      end
    end
  end
end
