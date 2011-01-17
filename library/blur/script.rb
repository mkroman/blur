# encoding: utf-8

module Blur
  class Script < Module
    attr_accessor :name, :author, :version, :client
    
    def evaluated?; @evaluated end
    
    def initialize path
      @path = path
      @evaluated = false
      
      if evaluate and @evaluated
        __send__ :loaded if respond_to? :loaded
      end
    end
    
    def Script name, version = [1,0], author = nil, &block
      @name    = name
      @author  = author
      @version = version
      
      instance_eval &block
    end
    
    def inspect
      %{#<#{self.class.name} @name=#{@name.inspect} @version=#{@version.inspect} @author=#{@author.inspect}>}
    end
    
  private
  
    def evaluate
      begin
        if module_eval File.read(@path), File.basename(@path), 0
          @evaluated = true
        end
      rescue Exception => exception
        puts "\e[1m#{File.basename @path}:#{exception.line + 1}: \e[31merror:\e[39m #{exception.message}\e[0m"
      end
    end
  end
end