# encoding: utf-8

module Pulse
  class Script < Module

    def initialize path, client
      @path, @client = path, client
      process
      __send__ :loaded if respond_to? :loaded
    end

    def Script name, version = [1, 0, 0], author = nil, &block
      @name, @version, @author = name, version, author
      instance_eval &block
    end

    def loaded?; @loaded == true end

    def unload!
      __send__ :unloaded if respond_to? :unloaded
      @client.scripts.delete self
    end

  private
    def process
      module_eval File.read(@path), File.basename(@path), 0

      @loaded = true
    rescue
      @loaded = false

      puts "Parse error: #{$!.message}"
    end
  end
end
