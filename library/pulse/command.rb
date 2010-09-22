# encoding: utf-8

module Pulse
  class Command
    attr_accessor :name, :params, :prefix

    HostPattern  = /^(:(\S+) )?(\S+)(.*)/
    ExtraPattern = /(?:^:| :)(.*)$/

    def self.parse data
      match = data.match HostPattern
      empty, prefix, name, params = match.captures

      if match = params.match(CommandPattern)
        params = match.pre_match.split << match[1]
      else
        params = params.split
      end

      new(name, params).tap do |this|
        this.prefix = prefix
      end
    end

    def initialize name, params = []
      @name, @params = name, params
    end
  end
end
