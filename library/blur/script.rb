# encoding: utf-8

module Blur
  # The +Script+ class is used for encapsulating dynamically loaded ruby scripts.
  #
  # The {Script#Script} method is then used to shape the DSL-language to make
  # writing Blur scripts a breeze.
  #
  # @todo add examples in the documentation
  # @see Script#Script
  class Script
    include Logging
    include Evaluable
    include DSL

    Emissions = [:connection_ready, :topic_change, :user_rename, :message,
                 :private_message, :user_entered, :user_left, :user_quit,
                 :user_kicked, :topic, :user_mode, :channel_mode,
                 :channel_created, :channel_who_reply]

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
      
      if evaluate_source_file path
        cache.load if Cache.exists? @__name

        Emissions.each do |emission|
          @__emissions.push emission if respond_to? emission
        end
        
        __send__ :loaded if respond_to? :loaded
        __send__ :module_init if respond_to? :module_init
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
    def Script name, options = {}, &block
      @__name = name

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
  end
end
