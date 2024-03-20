# frozen_string_literal: true

require 'yaml'
require 'socket'
require 'openssl'

require 'async'
require 'async/io'
require 'async/io/stream'
require 'async/io/protocol/line'
require 'deep_merge/rails_compat'
require 'ircparser'
require 'semantic_logger'

# Require all library files.
require_relative 'blur/version'
require_relative 'blur/callbacks'
require_relative 'blur/script'
require_relative 'blur/script_cache'
require_relative 'blur/network'
require_relative 'blur/client'
require_relative 'blur/user'
require_relative 'blur/channel'
require_relative 'blur/network/isupport'
require_relative 'blur/network/connection'
require_relative 'blur/url_handling'

# Blur is a very modular IRC-framework for ruby.
#
# It allows the developer to extend it in multiple ways.
# It can be by handlers, scripts, communications, and what have you.
module Blur
  # Client error.
  class ClientError < StandardError; end

  # Configuration file error.
  class ConfigError < StandardError; end

  # Creates a new superscript class and inserts it into the list of scripts.
  def self.Script(name, *_args, &) # rubocop:disable Naming/MethodName
    klass = Class.new(SuperScript)
    klass.name = name
    klass.events = {}
    klass.class_exec(&)
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
    scripts.each_value(&:deinit)
    scripts.clear
  end

  # Instantiates a client with given options and then makes the client instance
  # evaluate the given block to form a DSL.
  #
  # @note The idea is that this should never stop or return anything.
  # @param [Hash] options the options for the client.
  # @option options [Array] networks list of hashes that contain network
  #   options.
  def self.connect(options = {}, &block)
    Client.new(options).tap do |client|
      client.instance_eval(&block)
    end.connect
  end
end
