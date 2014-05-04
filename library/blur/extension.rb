# encoding: utf-8

module Blur
  # +Extension+ provides a sort of modules for scripts, for common functionality.
  #
  # Think of it as a kind of scripts for scripts.
  class Extension
    def self.name
      class_variable_get :@@name
    end

    def self.inspect
      %%#<Blur::Extension #{name}>%
    end
  end
end
