# encoding: utf-8

module Blur
  # The +Script+ class is used for encapsulating dynamically loaded ruby scripts.
  #
  # The {Script#Script} method is then used to shape the DSL-language to make
  # writing Blur scripts a breeze.
  #
  # @todo add examples in the documentation
  # @see Script#Script
  class Script < Module
    # @return the name of the script.
    attr_accessor :__name
    # @return the author of the script.
    attr_accessor :__author
    # @return the version of the script.
    attr_accessor :__version
    # @return the path in which the script remains.
    attr_accessor :__path
    # Can be used inside the script to act with the client itself.
    # @return [Network::Client] the client delegate.
    attr_accessor :__client
    
    # Check to see if the script has been evaluated.
    def evaluated?; @__evaluated end
    
    # Instantiates a script and evaluates the contents which remain in +path+.
    def initialize path
      @__path = path
      @__evaluated = false
      
      if evaluate and @__evaluated
        cache.load if Cache.exists? @__name
        
        __send__ :loaded if respond_to? :loaded
      end
    end
    
    # Make it a DSL-way of writing a script.
    #
    # @example
    #   Script :example do
    #     def connection_ready network
    #       # …
    #     end
    #   end
    def Script name, version = [1,0], author = nil, &block
      @__name    = name
      @__author  = author
      @__version = version
      
      instance_eval &block
      
      true
    end
    
    # Unload the script and save the cache, if present.
    def unload!
      cache.save if @__cache
      __send__ :unloaded if respond_to? :unloaded

      @__cache = nil
    end

    # Access another script with name +name+.
    #
    # @return [Script] the script with the name +name+, or nil.
    def script name
      @__client.scripts.find { |script| script.__name == name }
    end
    
    # Get the cache, if none, instantiate a new cache.
    def cache
      @__cache ||= Cache.new self
    end
    
    # Convert it to a debug-friendly format.
    def inspect
      %{#<#{self.class.name} @name=#{@__name.inspect} @version=#{@__version.inspect} @author=#{@__author.inspect}>}
    end
    
  private
  
    # Attempt to evaluate the contents of the script.
    def evaluate
      module_eval File.read(@__path), File.basename(@__path), 0
      @__evaluated = true
    rescue Exception => exception
      puts "#{File.basename(@__path) ^ :bold}:#{exception.line.to_s ^ :bold}: #{"error:" ^ :red} #{exception.message ^ :bold}"
    end
  end
end
