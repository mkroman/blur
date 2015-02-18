# encoding: utf-8

module Blur
  # The +Script+ class is used for encapsulating dynamically loaded ruby scripts.
  class Script
    include DSL
    include Callbacks

    # Script-specific configuration variables.
    #
    # Can be defined in the `scripts` key in the client configuration.
    attr_accessor :config

    # Get the script name.
    #
    # @return [Symbol] the script name.
    def self.name
      class_variable_get :@@name
    end

    # Get a reference to the running Blur::Client instance.
    #
    # @return [Client] the running client instance.
    def self.client; class_variable_get :@@client end

    # Called when a new script block is called.
    #
    # @param args the extra arguments to the Script block.
    def self.script_init *args; end

    # Get a printable description of the script class.
    #
    # @return [String] the printable description.
    def self.inspect
      %%#<Blur::Script @@name=#{name.inspect}>%
    end

    # Alias for `inspect`.
    def self.to_s
      inspect
    end

    # Get a reference to the running Blur::Client instance.
    #
    # @return [Client] the running client instance.
    def client; self.class.client end

    # Get a printable description of the script instance.
    #
    # @return [String] the printable description.
    def inspect
      %%#<Blur::Script::0x#{object_id.to_s 16}(#{self.class.name.inspect})>%
    end

    # Include a module inside the script.
    #
    # @param [Array] args list of modules to include.
    def include *args
      args.select{|arg| arg.is_a? Module }.each do |modul|
        modul.module_init self if modul.respond_to? :module_init

        self.class.__send__ :include, modul
      end
    end

    # Get the script name.
    #
    # @return [String] the script name.
    def script_name
      self.class.name
    end

    # Alias for `inspect`.
    def to_s
      inspect
    end
  end
end
