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

    def self.add_module modul, name = nil
      if name
        self.const_set name, modul
      else
        name = modul.name.split('::').last

        self.const_set name, modul
      end
    end

    # Return a list of scripts defined in this scope.
    #
    # @return [Array<Script>] a list of scripts.
    attr_accessor :scripts

    # Constructor for a new scope.
    def initialize
      @scripts = []
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

    # Inspect the object.
    def inspect
      %%#<Blur::Scope @scripts=#{@scripts.inspect}>%
    end

    # Inspect the object.
    def to_s
      inspect
    end
  end
end
