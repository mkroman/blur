# encoding: utf-8

module Pulse
  class Script
    class Cache
      def initialize script
        @script = script
      end

    private
      def path
        "#{File.expand_path $0}/cache/#{@script.name}_#{@index}"
      end
    end
  end
end
