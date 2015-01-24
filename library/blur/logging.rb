# encoding: utf-8

# Temporary replacement for majic's color method.
class String
  def ^ c
    self
  end
end

module Blur
  # Very crude logging module.
  module Logging
    Levels = [:debug, :info, :warn, :error, :fatal]

    class Logger
      Levels.each do |level|
        define_method level do |*messages|
          Logging.mutex.synchronize do
            messages.each{|m| puts "%-8s %s" % [level.to_s.upcase, m] }
          end
        end
      end
    end

    @mutex = Mutex.new
    @logger = Logger.new

    class << self
      attr_reader :mutex
      attr_reader :logger
    end

    def log *messages
      if messages.empty?
        Logging.logger
      else
        Logging.logger.debug *messages
      end
    end
  end
end
