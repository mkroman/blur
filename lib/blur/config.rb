# frozen_string_literal: true

require 'yaml'

module Blur
  # Configuration load or validation error.
  class ConfigError < StandardError; end

  # Load an validate a client configuration from a YAML file.
  class Config
    # @return [String] the directory where scripts can place cache files
    attr_reader :cache_dir

    # @return [Array<Network>] list of network configurations
    attr_accessor :networks

    # @return [Hash<String, Hash>] the configuration values for scripts
    attr_accessor :scripts

    # @return [String] the path to the directory that contains scripts
    attr_reader :scripts_dir

    # @return [String] the default directory to look for scripts in
    DEFAULT_SCRIPTS_DIR = 'scripts/'

    def initialize
      @path = ''
      @networks = []
      @cache_dir = 'cache/'
      @scripts = {}
      @scripts_dir = DEFAULT_SCRIPTS_DIR
    end

    def parse_file!(path)
      data = YAML.safe_load_file(path, aliases: true)

      # Parse and validate script configuration
      scripts = data['scripts']

      if scripts
        raise ConfigError, "Option `scripts' must be a Hash" unless scripts.is_a?(Hash)

        if scripts.keys.find { |key| !key.is_a?(String) }
          raise ConfigError, "Option `scripts' must only use strings as keys"
        end
      end

      # Parse and validate network configurations
      networks = data['networks']

      raise ConfigError, "Option `networks' is missing" unless networks
      raise ConfigError, "Option `networks' must be a list of networks" unless networks.is_a?(Array)

      import_networks(networks)
      import_scripts(scripts)
    end

    def self.load_file(path)
      Config.new.tap do |conf|
        conf.parse_file!(path)
      end
    end

    private

    def import_networks(networks)
      networks.each_with_index do |network, index|
        @networks << network if validate_network_config(network, index)
      end
    end

    def import_scripts(scripts)
      @scripts = scripts
    end

    def validate_network_config(network, index)
      required_keys = %w[nickname hostname]
      required_keys.each do |key|
        value = network[key]

        raise ConfigError, "Option `networks[#{index}].#{key}' is missing" unless value
      end
    end
  end
end
