# encoding: utf-8

module Pulse
  class Queue
    def initialize
      @queue = []
    end

    def process socket
      @socket ||= socket
      @thread = Thread.current

      while @thread.alive?
        if command = @queue.shift
          puts ">> #{command}"
          @socket.write "#{command}\n"
        else
          Thread.stop
        end
      end
    end

    def << command
      @queue << command
      @thread.run unless @thread.nil?
    end
  end
end
