# encoding: utf-8

module Pulse
  class Script < Module
    attr_accessor :name, :author, :version, :path

    def initialize path, client
      @path, @client, @loaded = path, client, false

      cache.load if has_cache?
      emit :loaded if evaluate_script
    end

    def Script name, version = [1,0,0], author = nil, &block
      @name, @version, @author = name, version, author

      instance_eval &block
    end

    def cache_for name; script = @client.scripts.find { |script| script.name == name } ? script.cache : nil end

    def emit method, *args; __send__ method, *args if respond_to? method end
    def script name; @client.scripts.find { |script| script.name == name } end
    def cache; @cache ||= Cache.new self end

    def has_cache?; File.exists? "#{File.expand_path File.dirname $0}/cache/#@name.yml" end
    def loaded?; @loaded == true end

    def unload!; cache.save if @cache; emit :unloaded end

    def to_yaml opts = {}; @name.to_yaml opts end

    def inspect
      %{#<#{self.class.name} @name=#{@name.inspect} @version=#{@version.inspect} @author=#{@author.inspect}}
    end

  private

    def evaluate_script
      @loaded = true if module_eval File.read(@path), File.basename(@path), 0
    rescue
      puts "Parse error: #{$!.message}"
    end
  end
end
