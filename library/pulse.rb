# encoding: utf-8

require 'socket'
require 'pulse/user'
require 'pulse/queue'
require 'pulse/client'
require 'pulse/script'
require 'pulse/channel'
require 'pulse/command'
require 'pulse/settings'
require 'pulse/connection'
require 'pulse/enhancements'

Thread.abort_on_exception = true

module Pulse
  Version = 1, 0, 0

  class << self
    def connect options, &block
      Client.new(options).tap do |client|
        client.instance_eval &block
      end.connect
    end
  end
end
