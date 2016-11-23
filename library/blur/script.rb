# encoding: utf-8

module Blur
  class SuperScript
    class << self
      attr_accessor :name, :authors, :version, :description, :events

      # Sets the author.
      # 
      # @example
      #   Author 'John Doe <john.doe@example.com>'
      def Author *authors
        @authors = authors
      end

      # Sets the description.
      #
      # @example
      #   Description 'This is an example script.'
      def Description description
        @description = description
      end

      # Sets the version.
      #
      # @example
      #   Version '1.0.0'
      def Version version
        @version = version
      end

      # Registers events to certain functions.
      #
      # @example
      #   register! message: :on_message, connection_ready: :connected
      def register! *args
        args.each do |events|
          if events.is_a? Array
            (@events[event] ||= []).concat events
          else
            events.each{|event, method| (@events[event] ||= []) << method }
          end
        end
      end

      def to_s; inspect end
      def inspect; %%#<SuperScript:0x#{self.object_id.to_s 16}>% end

      alias :author :authors
    end

    attr_accessor :_client_ref, :config

    def unloaded
    end

    def inspect
      "#<Script(#{self.class.name.inspect}) " \
        "@author=#{self.class.author.inspect} " \
        "@version=#{self.class.version.inspect} " \
        "@description=#{self.class.description.inspect}>"
    end

    def to_s; inspect end
  end
end
