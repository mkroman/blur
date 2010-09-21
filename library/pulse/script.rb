# encoding: utf-8

module Pulse
  class Script
    def initialize
      # …
    end

    def cache
      @cache ||= Cache.new self
    end
  end
end
