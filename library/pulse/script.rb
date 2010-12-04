# encoding: utf-8

module Pulse
  class Script < Module

    attr_accessor :name, :author, :version

    def initialize path, client
      @path, @client = path, client
      @loaded = false

      evaluate_script
      cache.load if has_cache?
      __send__ :loaded if respond_to? :loaded
    end

    def Script name, version = [1, 0, 0], author = nil, &block
      @name, @version, @author = name, version, author
      instance_eval &block
    end

    def loaded?; @loaded == true end

    def unload!
      cache.save if @cache
      __send__ :unloaded if respond_to? :unloaded
    end

    def to_yaml opts = {}; @name.to_yaml opts end

    def inspect
      %{#<#{self.class.name} @name=#{@name.inspect} @version=#{@version.inspect} @author=#{@author.inspect}}
    end

    def cache_for name
      script = @client.scripts.find { |script| script.name == name }
      script ? script.cache : nil
    end

    def script name; @client.scripts.find { |script| script.name == name } end

    def has_cache?
      File.exists? "#{File.expand_path File.dirname $0}/cache/#@name.yml"
    end

    def cache; @cache ||= Cache.new self end

  private

    def evaluate_script
      @loaded = true if module_eval File.read(@path), File.basename(@path), 0
    rescue
      puts "Parse error: #{$!.message}"
    end

  end
end
