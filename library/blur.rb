# encoding: utf-8

require 'yaml'
require 'socket'
require 'base64'
require 'ostruct'
require 'openssl'

require 'deep_merge/rails_compat'
require 'eventmachine'
require 'ircparser'

# Require all library files.
require 'blur/logging'
require 'blur/version'
require 'blur/callbacks'
require 'blur/script'
require 'blur/script_cache'
require 'blur/network'
require 'blur/client'
require 'blur/user'
require 'blur/channel'
require 'blur/network/isupport'
require 'blur/network/connection'

# Blur is a very modular IRC-framework for ruby.
#
# It allows the developer to extend it in multiple ways.
# It can be by handlers, scripts, communications, and what have you.
module Blur
  class ConfigError < StandardError; end

  # Creates a new superscript class and inserts it into the list of scripts.
  def self.Script name, *args, &block
    klass = Class.new SuperScript
    klass.name = name
    klass.events = {}
    klass.class_exec &block
    klass.init

    scripts[name] = klass
  end

  # Gets all superscript classes.
  def self.scripts
    @scripts ||= {}
  end

  # Resets all scripts.
  #
  # This method will call `deinit` on each script class before removing them to
  # give them a chance to clean up.
  def self.reset_scripts!
    scripts.each_value &:deinit
    scripts.clear
  end

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
