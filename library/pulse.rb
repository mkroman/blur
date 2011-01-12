# encoding: utf-8

require 'yaml'
require 'socket'
require 'ostruct'

Dir.glob("#{File.dirname __FILE__}/pulse/**/*.rb").each &method(:require)

module Pulse
  class << Version = [1,4]
    def to_s; join '.' end
  end

  def self.connect options, &block
    Client.new(options).tap do |client|
      client.instance_eval &block
    end.connect
  end
end
