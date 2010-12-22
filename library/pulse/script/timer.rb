# encoding: utf-8

module Pulse
  class Script < Module
    class Timer
      def initialize options = {}, &block
        @delay = options[:in] or 1.0
        @callback = block if block_given?
      end

      def start
        @thread ||= Thread.new do
          loop { @callback.call; sleep @delay }
        end
      end
    end
  end
end
