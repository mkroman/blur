# encoding: utf-8

module Pulse
  class Cache
    def initialize script
      @script = script
    end

  private
    def path
      File.expand_path $0
    end
  end
end
