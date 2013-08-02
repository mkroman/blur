# encoding: utf-8

require 'pp'
require 'yaml'
require 'majic'
require 'socket'
require 'ostruct'
require 'openssl'
require 'eventmachine'

# Require all library files.
require 'blur/client'
require 'blur/script'
require 'blur/network'
require 'blur/encryption'
require 'blur/enhancements'
require 'blur/script/cache'
require 'blur/network/user'
require 'blur/script/fantasy'
require 'blur/network/channel'
require 'blur/network/command'
require 'blur/network/connection'
require 'blur/script/messageparsing'

# Blur is a very modular IRC-framework for ruby.
#
# It allows the developer to extend it in multiple ways.
# It can be by handlers, scripts, communications, and what have you.
module Blur
  # The major and minor version-values of Blur.
  Version = "1.7.3"

  # Instantiates a client with given options and then makes the client instance
  # evaluate the given block to form a DSL.
  #
  # @note The idea is that this should never stop or return anything.
  # @param [Hash] options the options for the client.
  # @option options [Array] networks list of hashes that contain network
  #   options.
  def self.connect options = {}, &block
    Client.new(options).tap do |client|
      client.instance_eval &block
    end.connect
  end
end
