# encoding: utf-8

module Blur
  class Script < Module
    attr_accessor :name, :author, :version, :path, :client
    
    def evaluated?; @evaluated end
    
    def initialize path
      @path = path
      @evaluated = false
      
      if evaluate and @evaluated
        cache.load if Cache.exists? @name
        
        __send__ :loaded if respond_to? :loaded
      end
    end
    
    def Script name, version = [1,0], author = nil, &block
      @name    = name
      @author  = author
      @version = version
      
      instance_eval &block
      
      true
    end
    
    def unload!
      @cache.save if @cache
      
      __send__ :unloaded if respond_to? :unloaded
    end
    
    def cache
      @cache ||= Cache.new self
    end
    
    def inspect
      %{#<#{self.class.name} @name=#{@name.inspect} @version=#{@version.inspect} @author=#{@author.inspect}>}
    end
    
  private
  
    def evaluate
      if module_eval File.read(@path), File.basename(@path), 0
        @evaluated = true
      end
    rescue Exception => exception
      puts "\e[1m#{File.basename @path}:#{exception.line}: \e[31merror:\e[39m #{exception.message}\e[0m"
    end
  end
end