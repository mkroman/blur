# encoding: utf-8

module Blur
  # The +Script+ class is used for encapsulating dynamically loaded ruby scripts.
  class Script
    include DSL
    include Callbacks

    @@client = 5

    # Get the script name.
    #
    # @return [Symbol] the script name.
    def self.name
      class_variable_get :@@name
    end

    def self.client
      class_variable_get :@@client
    end

    def client
      self.class.class_variable_get :@@client
    end

    # Called when a new script block is called.
    #
    # @param args the extra arguments to the Script block.
    def self.script_init *args
      options = args.pop if args.last.is_a? Hash
    end

    # Inspect the script class.
    def self.inspect
      %%#<Blur::Script @@name=#{name.inspect}>%
    end

    # Inspect the script instance.
    def inspect
      %%#<Blur::Script::0x#{object_id.to_s 16}(#{self.class.name.inspect})>%
    end

    def include *args
      args.select{|arg| arg.is_a? Module }.each do |modul|
        modul.module_init self if modul.respond_to? :module_init

        self.class.__send__ :include, modul
      end
    end

    # Inspect the script instance.
    def to_s
      inspect
    end

    def self.to_s
      inspect
    end
  end
end
