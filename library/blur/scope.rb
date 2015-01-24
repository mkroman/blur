# encoding: utf-8

module Blur
  # %Scope is a contextual scope used when loading scripts.
  #
  # It serves as a way to sanitize the scope in which scripts are evaluated.
  class Scope
    # Evaluate the contents of a file in a new, temporary and anonymous module
    # scope.
    #
    # @param path [String] the path to the file.
    def eval_file path
      unless File.exists? path
        raise Errno::ENOENT, "Tried to evaluate non-existing file `#{path}'"
      end

      modul = meta_module
      modul.module_eval File.read(path), path
    end

    # Return a list of scripts defined in this scope.
    #
    # @return [Array<Script>] a list of scripts.
    attr_accessor :scripts

    # Constructor for a new scope.
    #
    # @param client a reference to the client that owns this scope.
    def initialize client
      @client = client
      @scripts = []
    end

    # Create a new anonymous module with a #Script method that creates a new
    # script class.
    def meta_module &block
      mod_klass = Class.new Module
      mod_klass.__send__ :define_method, :Script do |name, *args, &script_block|
        klass = Class.new Script
        klass.class_variable_set :@@name, name
        klass.class_eval &script_block
        klass.script_init *args

        @_blur_scope.scripts << klass.new
      end

      mod = mod_klass.new
      mod.instance_variable_set :@_blur_scope, self

      yield mod if block_given?

      mod_klass = nil
      mod
    end

    # Inspect the scope instance.
    def inspect
      %%#<Blur::Scope::0x#{object_id.to_s 16} @scripts=#{@scripts.inspect}>%
    end

    # Inspect the script instance.
    def to_s
      inspect
    end
  end
end
