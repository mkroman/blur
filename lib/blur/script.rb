# frozen_string_literal: true

module Blur
  module Commands
    # This is a command look-up-table with an autoincrementing index.
    class CommandLUT
      attr_accessor :commands

      def initialize
        @index = -1
        @commands = {}
      end

      # Inserts the command to the LUT.
      #
      # @returns the index.
      def <<(command)
        @commands[command] = @index += 1
        @index
      end
    end

    module ClassMethods
      # Creates a new command.
      #
      # @example
      #   command! '!ping' do |user, channel, args|
      #     channel.say "#{user}: pong"
      #   end
      def command!(command, *_args, &)
        id = (command_lut << command)
        define_method(:"_command_#{id}", &)
      end
    end

    def self.included(klass)
      class << klass
        attr_accessor :command_lut
      end

      klass.extend ClassMethods
      klass.command_lut = CommandLUT.new
      klass.register!(message: lambda do |script, user, channel, line, tags|
        command, args = line.split(' ', 2)
        return unless command

        if (id = klass.command_lut.commands[command.downcase])
          script.__send__(:"_command_#{id}", user, channel, args, tags)
        end
      end)
    end
  end

  class SuperScript
    class << self
      attr_accessor :name, :authors, :version, :description, :events

      # Sets the author.
      #
      # @example
      #   Author 'John Doe <john.doe@example.com>'
      def Author(*authors) # rubocop:disable Naming/MethodName
        @authors = authors
      end

      # Sets the description.
      #
      # @example
      #   Description 'This is an example script.'
      def Description(description) # rubocop:disable Naming/MethodName
        @description = description
      end

      # Sets the version.
      #
      # @example
      #   Version '1.0.0'
      def Version(version) # rubocop:disable Naming/MethodName
        @version = version
      end

      # Registers events to certain functions.
      #
      # @example
      #   register! message: :on_message, connection_ready: :connected
      def register!(*args)
        args.each do |events|
          case events
          when Hash
            events.each do |event, method_name|
              register_event!(event, method_name)
            end
          when Array
            register!(*events)
          when Symbol
            register_event!(events)
          end
        end
      end

      # Adds the given event +name+ and the name of the method to call once the
      # event is emitted.
      def register_event!(name, method_name = name)
        (@events[name] ||= []) << method_name
      end

      def to_s
        inspect
      end

      def inspect
        %(#<SuperScript:0x#{object_id.to_s 16}>)
      end

      alias author authors
      alias Authors Author
    end

    # Called when when the superscript has been loaded and added to the list of
    # superscripts.
    def self.init; end

    # Called right before the script is being removed from the list of
    # superscripts.
    def self.deinit; end

    # Reference to the main client that holds the script.
    attr_accessor :_client_ref

    # Script-specific configuration that is read from the main configuration
    # file.
    attr_accessor :config

    attr_accessor :cache

    # Called right before the instance of the script is being removed.
    def unloaded; end

    # Gets the instantiated script with +name+.
    def script(name)
      _client_ref.scripts[name]
    end

    # Gets a human-readable representation of the script.
    def inspect
      "#<Script(#{self.class.name.inspect}) " \
        "@author=#{self.class.author.inspect} " \
        "@version=#{self.class.version.inspect} " \
        "@description=#{self.class.description.inspect}>"
    end

    def to_s
      inspect
    end
  end
end
