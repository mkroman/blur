# encoding: utf-8

require 'yaml'
require 'socket'

Dir.glob("#{File.dirname __FILE__}/pulse/**/*.rb").each &method(:require)
Thread.abort_on_exception = true

module Pulse
  class << Version = [1,2]
    def to_s; join ?. end
  end

  class << self
    def connect options, &block
      puts "=> Pulse #{Version}"

      Client.new(options).tap do |client|
        client.instance_eval &block
      end.connect
    end
  end
end
