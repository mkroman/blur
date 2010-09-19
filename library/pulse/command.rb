# encoding: utf-8

module Pulse
  class Command
    def initialize name, params = []
      self.name  = name
      parameters = params
    end

    def name= name
      if name.is_a? String and name =~ /^\d+$/
        @name = name.to_i
      else
        @name = name
      end
    end
  end
end
