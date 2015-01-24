# encoding: utf-8

require 'yaml'
require 'socket'
require 'ostruct'
require 'openssl'
require 'eventmachine'

# Require all library files.
require 'blur/logging'
require 'blur/version'
require 'blur/callbacks'
require 'blur/scope'
require 'blur/client'
require 'blur/script/dsl'
require 'blur/extension'
require 'blur/script'
require 'blur/network'
require 'blur/encryption'
require 'blur/enhancements'
require 'blur/script/cache'
require 'blur/network/user'
require 'blur/network/channel'
require 'blur/network/command'
require 'blur/network/isupport'
require 'blur/network/connection'
require 'blur/scope/commands'

# Blur is a very modular IRC-framework for ruby.
#
# It allows the developer to extend it in multiple ways.
# It can be by handlers, scripts, communications, and what have you.
module Blur
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
