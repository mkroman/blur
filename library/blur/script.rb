# encoding: utf-8

module Blur
  # The +Script+ class is used for encapsulating dynamically loaded ruby scripts.
  class Script
    include DSL
    include Callbacks

    # Get the script name.
    #
    # @return [Symbol] the script name.
    def self.name
      class_variable_get :@@name
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
      %%#<Blur::Script::0x#{object_id.to_s 16}(#{@@name})>%
    end

    # Inspect the script instance.
    def to_s
      inspect
    end
  end
end
