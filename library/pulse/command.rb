# encoding: utf-8

module Pulse
  class Command
    attr_accessor :name, :params

    Pattern = //

    def self.parse data
      data
    end

    def initialize name, params = []
      @name, @params = name, params
    end

    alias_method :parameters, :params
  end
end
