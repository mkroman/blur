# encoding: utf-8

module Pulse
  class Queue
    SleepDuration = 2
    Timelapse = 4
    Amount = 3

    # Sleep SleepDuration if the last Amount messages was sent with a TimeBound second difference.

    def initialize
      @queue, @history, @sleeping = [], (0..Amount).map { |i| 0 }, false
    end

    def process socket
      @socket ||= socket
      @thread = Thread.current

      while @thread.alive?
        if command = @queue.shift

          @history.shift and @history << Time.now.to_i

          if spam?
            @sleeping = true
            sleep SleepDuration
            @sleeping = false
          end

          @socket.write "#{command}\n"
        else
          Thread.stop
        end
      end
    end

    def spam?
      @history.select { |time| time >= Time.now.to_i - Timelapse }.count >= Amount
    end

    def << command
      @queue << command
      @thread.run if @thread and not @sleeping
   end
  end
end
