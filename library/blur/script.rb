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
    include Logging

    Emissions = [:connection_ready, :topic_change, :user_rename, :message,
                 :private_message, :user_entered, :user_left, :user_quit,
                 :user_kicked, :topic, :user_mode, :channel_mode]

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
    # @return [Array] a list of handled emissions.
    attr_accessor :__emissions
    
    # Check to see if the script has been evaluated.
    def evaluated?; @__evaluated end
    
    # Instantiates a script and evaluates the contents which remain in +path+.
    def initialize path
      @__path = path
      @__evaluated = false
      @__emissions = []
      
      if evaluate and @__evaluated
        cache.load if Cache.exists? @__name

        Emissions.each do |emission|
          @__emissions.push emission if respond_to? emission
        end
        
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
      File.basename @__path
    end
    
  private
  
    # Attempt to evaluate the contents of the script.
    def evaluate
      instance_eval File.read(@__path), File.basename(@__path), 0
      @__evaluated = true
    rescue Exception => exception
      log.error "#{exception.message ^ :bold} on line #{exception.line.to_s ^ :bold}"
    end
  end
end
