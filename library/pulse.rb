# encoding: utf-8

require 'yaml'
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
require 'pulse/conversation'
require 'pulse/script/cache'

Thread.abort_on_exception = true

module Pulse
  class << Version = [1,1]
    def to_s; join ?. end
  end

  class << self
    def connect options, &block
      puts "=> Pulse #{Pulse::Version}"

      Client.new(options).tap do |client|
        client.instance_eval &block
      end.connect
    end
  end
end
