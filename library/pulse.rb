# encoding: utf-8

require 'pulse/queue'
require 'pulse/client'
require 'pulse/command'
require 'pulse/connection'

module Pulse
  VERSION = [1, 0, 0]

  class << self
    def connect options, &proc
      Client.new(options).tap do |client|
        client.instance_eval &proc
      end.connect
    end
  end
end
