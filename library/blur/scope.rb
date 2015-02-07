# encoding: utf-8

module Blur
  # %Scope is a contextual scope used when loading scripts.
  #
  # It serves as a way to sanitize the scope in which scripts are evaluated.
  class Scope
    ScriptError = Class.new StandardError
    ScopeError = Class.new StandardError

    # Evaluate the contents of a file in a new, temporary and anonymous module
    # scope.
    #
    # @param path [String] the path to the file.
    def load_scripts_from_file path, &block
      unless File.exists? path
        raise Errno::ENOENT, "Tried to evaluate non-existing file `#{path}'"
      end

      modul = meta_module &block
      begin
        modul.module_eval File.read(path), path
      rescue Exception => e
        if e.is_a? ScriptError
          # Pass it through
          raise e
        else
          raise ScopeError,
            "#{e.class} raised during load of the global script scope: #{e.message}",
            e.backtrace
        end
      end
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
      client    = @client
      mod_klass = Class.new Module

      mod_klass.__send__ :define_method, :Script do |name, *args, &script_block|
        klass = Class.new Script
        klass.class_variable_set :@@name, name
        klass.class_variable_set :@@client, client
        klass.script_init *args

        @_blur_scope.scripts << klass

        klass.new.tap do |skript|
          begin
            skript.instance_eval &script_block
          rescue Exception => e
            raise ScriptError,
              "#{e.class} raised when evaluating script block for script `#{name.inspect}': #{e.message}",
              e.backtrace
          end

          skript.__send__ :initialize
          yield skript if block_given?
        end
      end

      mod_klass.new.tap do |mod|
        mod.instance_variable_set :@_blur_scope, self
      end
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
