# frozen_string_literal: true

module Blur
  module Callbacks
    # Get a list of callbacks registered.
    #
    # @returns [Array] the list of callbacks
    def callbacks
      @callbacks ||= {}
    end

    # Emit a new event with given arguments.
    #
    # @param name [Symbol] The event name.
    # @param args [optional, Array] The list of arguments to pass.
    # @return [true, false] True if any callbacks were invoked, nil otherwise
    def emit(name, *args)
      # Trigger callbacks in scripts before triggering events in the client.
      notify_scripts(name, *args)

      matching_callbacks = callbacks[name]
      return false unless matching_callbacks&.any?

      matching_callbacks.each { |callback| callback.call(*args) }
    end

    # Add a new event callback.
    #
    # @param name [Symbol] The event name.
    # @yield [args, ...] The arguments passed from #emit.
    def on(name, &block)
      (callbacks[name] ||= []) << block
    end

    protected

    def notify_scripts(name, *args)
      scripts = @scripts.values.select { |script| script.class.events.key?(name) }
      scripts.each do |script|
        script.class.events[name].each do |method|
          if method.is_a?(Proc)
            method.call(script, *args)
          else
            script.__send__(method, *args)
          end
        end
      rescue StandardError => e
        warn "#{e.class}: #{e.message}"
        warn nil, 'Backtrace:', '---', e.backtrace
      end
    end
  end
end
