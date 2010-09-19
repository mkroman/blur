# encoding: utf-8

module Pulse
  class Queue

    def initialize socket
      @socket, @queue = socket, []
    end

    def process
      if command = @queue.shift
        @socket.write "#{command}\n"
      end
    end

    def push command
      @queue << command
    end

    alias_method :<<, :push
  end
end
