# encoding: utf-8

module Blur
  class Script < Module
    attr_accessor :__name, :__author, :__version, :__path, :__client
    
    def evaluated?; @__evaluated end
    
    def initialize path
      @__path = path
      @__evaluated = false
      
      if evaluate and @__evaluated
        cache.load if Cache.exists? @__name
        
        __send__ :loaded if respond_to? :loaded
      end
    end
    
    def Script name, version = [1,0], author = nil, &block
      @__name    = name
      @__author  = author
      @__version = version
      
      instance_eval &block
      
      true
    end
    
    def unload!
      cache.save if @__cache
      __send__ :unloaded if respond_to? :unloaded

      @__cache = nil
    end

    def script name
      @__client.scripts.find { |script| script.__name == name }
    end
    
    def cache
      @__cache ||= Cache.new self
    end
    
    def inspect
      %{#<#{self.class.name} @name=#{@__name.inspect} @version=#{@__version.inspect} @author=#{@__author.inspect}>}
    end
    
  private
  
    def evaluate
      module_eval File.read(@__path), File.basename(@__path), 0
      @__evaluated = true
    rescue Exception => exception
      puts "#{File.basename(@__path) ^ :bold}:#{exception.line.to_s ^ :bold}: #{"error:" ^ :red} #{exception.message ^ :bold}"
    end
  end
end
