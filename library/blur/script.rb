# encoding: utf-8

module Blur
  # The +Script+ class is used for encapsulating dynamically loaded ruby scripts.
  #
  # The {Script#Script} method is then used to shape the DSL-language to make
  # writing Blur scripts a breeze.
  #
  # @see Script#Script
  class Script
    include DSL

    # Get the script name.
    #
    # @return [Symbol] the script name.
    def self.name
      class_variable_get :@@name
    end

    def self.inspect
      %%#<Blur::Script #{name}>%
    end

    def initialize
    end

    def name
      @@name
      #self.class.class_variable_get :@@name
    end
  end
end
