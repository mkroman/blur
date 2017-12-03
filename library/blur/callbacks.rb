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
      EM.defer do
        notify_scripts name, *args if @scripts&.any?
      end

      if (callbacks = @@callbacks[name]) and callbacks.any?
        EM.defer do
          callbacks.each{|callback| callback.call *args }
        end
      end
    end

    # Add a new event callback.
    #
    # @param name [Symbol] The event name.
    # @yield [args, ...] The arguments passed from #emit.
    def on name, &block
      (@@callbacks[name] ||= []) << block
    end

  protected

    def notify_scripts name, *args
      scripts = @scripts.values.select{|script| script.class.events.key? name }
      scripts.each do |script|
        begin
          script.class.events[name].each do |method|
            if method.is_a? Proc
              method.call script, *args
            else
              script.__send__ method, *args
            end
          end
        rescue => exception
          STDERR.puts "#{exception.class}: #{exception.message}"
          STDERR.puts nil, 'Backtrace:', '---', exception.backtrace
        end
      end
    end
  end
end
