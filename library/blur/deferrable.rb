# encoding: utf-8

module Blur
  module Deferrable
    # Include the mixin.
    def self.included base
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      # Return the list of callbacks registered.
      #
      # If the callbacks stack isn't already initialized, then initialize it.
      def callbacks
        @callbacks ||= {}
      end

      # Emit a new event with given arguments.
      #
      # @param name [Symbol] The event name.
      # @param args [optional, Array] The list of arguments to pass.
      def emit name, *args
        callbacks = self.callbacks[name]

        return if callbacks.nil? or callbacks.empty?

        EM.defer do
          callbacks.each do |callback|
            callback.(*args)
          end
        end
      end

      # Add a new event callback.
      #
      # @param name [Symbol] The event name.
      # @yield [args, ...] The arguments passed from #emit.
      def on name, &block
        (callbacks[name] ||= []) << block
      end
    end
  end
end
