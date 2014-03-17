# encoding: utf-8

module Blur
  # +Extension+ provides a sort of modules for scripts, for common functionality.
  #
  # Think of it as a kind of scripts for scripts.
  class Extension
    include Evaluable
    include Script::DSL

    # @return the path in which the script remains.
    attr_accessor :__path
    # Can be used inside the script to act with the client itself.
    # @return [Network::Client] the client delegate.
    attr_accessor :__client

    # Instantiates a new extension context and evaluates the +path+ extension
    # file.
    def initialize path
      @__path = path

      if evaluate_source_file path
        log.info "Loaded extension #{@__path}"
      end
    end

    # Purely for DSL purposes.
    #
    # @example
    #   Extension :http do
    #     …
    #   end
    def Extension name, &block
      @__name = name
      
      instance_eval &block
      
      true
    end
  end
end