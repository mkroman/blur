# encoding: utf-8

module Pulse
  class Network
    def secure?; @secure == true end

    def self.for string
      host, port = string.split ?:

      new host, port or 6667, false
    end

    def initialize host, port = 6667, secure = false
      @host, @port, @secure = host, port, secure
    end
  end
end
