# encoding: utf-8

module Blur
  # %Scope is a contextual scope used when loading scripts or extensions.
  #
  # It serves as a way to sanitize the scope in which scripts are evaluated.
  class Scope < Module
    # Evaluate the contents of a file in a new scope.
    #
    # @param path [String] the path to the file.
    # @returns [Scope] the resulting scope.
    def self.eval_file path
      if File.exists? path
        scope = Scope.new

        File.open path, 'r' do |file|
          scope.module_eval file.read, path
        end

        return scope
      end
    end

    # Return a list of scripts defined in this scope.
    #
    # @return [Array<Script>] a list of scripts.
    attr_accessor :scripts

    # Return a list of extensions defined in this scope.
    #
    # @return [Array<Extension>] a list of extensions.
    attr_accessor :extensions

    # Constructor for a new scope.
    def initialize
      @scripts = []
      @extensions = []
    end

    # Create a new metaclass for evaluating a script block.
    #
    # @return [Array<Script>] the list of scripts.
    def Script name, *args, &block
      options = args.pop if args.last.is_a? Hash

      klass = Class.new Script
      klass.class_variable_set :@@name, name
      klass.class_eval &block

      scripts << klass
    end

    # Create a new metaclass and evaluate an extension block.
    #
    # This method is the entry point of our extension DSL.
    #
    # @return [Array<Extension>] the list of extensions.
    def Extension name, *args, &block
      options = args.pop if args.list.is_a? Hash

      klass = Class.new MetaClass
      klass.class_variable_set :@@name, name
      klass.class_eval &block

      extensions << klass
    end

    # Inspect the object.
    def inspect
      %%#<Blur::Scope @scripts=#{@scripts.inspect} @extensions=#{@extensions.inspect}>%
    end

    # Inspect the object.
    def to_s
      inspect
    end
  end
end
