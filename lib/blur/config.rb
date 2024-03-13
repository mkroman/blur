# frozen_string_literal: true

require 'yaml'

module Blur
  # Configuration load or validation error.
  class ConfigError < StandardError; end

  # Load an validate a client configuration from a YAML file.
  class Config

    # @return [Hash<String, Hash>] the configuration values for scripts
    attr_accessor :scripts

    # @return [Array<Network>] list of network configurations
    attr_accessor :networks

    # @return [String] the default directory to look for scripts in
    DEFAULT_SCRIPTS_DIR = 'scripts/'

    def initialize
      @path = ''
      @networks = []
      @scripts = {}
      @scripts_dir = DEFAULT_SCRIPTS_DIR
    end

    def parse_file!(path)
      data = YAML.safe_load_file(path, aliases: true)

      # Parse and validate network configurations
      networks = data['networks']

      raise ConfigError, "Option `networks' is missing" unless networks
      raise ConfigError, "Option `networks' must be a list of networks" unless networks.is_a?(Array)

      networks.each_with_index { |network, index| validate_network_config(network, index) }
    end

    def self.load_file(path)
      Config.new.tap do |conf|
        conf.parse_file!(path)
      end
    end

    private

    def validate_network_config(network, index)
      required_keys = %w[nickname hostname]

      required_keys.each do |key|
        value = network[key]

        raise ConfigError, "Option `networks[#{index}].#{key}' is missing" unless value
      end
    end
  end
end
