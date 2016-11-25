# encoding: utf-8

module Blur
  module Callbacks
    # Our list of callbacks.
    @@callbacks = {}

    # Get a list of callbacks registered.
    #
    # @returns [Array] the list of callbacks
    def callbacks
      @@callbacks
    end

    # Emit a new event with given arguments.
    #
    # @param name [Symbol] The event name.
    # @param args [optional, Array] The list of arguments to pass.
    def emit name, *args
      begin
        @scripts.select{|_, script| script.class.events.key? name }.each do |_, script|
          script.class.events[name].each do |method|
            if method.is_a? Proc
              method.call script, *args
            else
              script.__send__ method, *args
            end
          end
        end
      rescue => e
        puts "#{e.class}: #{e.message}"
        puts e.backtrace
      end

      callbacks = @@callbacks[name]
      return if callbacks.nil? or callbacks.empty?

      EM.defer do
        callbacks.each {|callback| callback.(*args) }
      end
    end

    # Add a new event callback.
    #
    # @param name [Symbol] The event name.
    # @yield [args, ...] The arguments passed from #emit.
    def on name, &block
      (@@callbacks[name] ||= []) << block
    end
  end
end
