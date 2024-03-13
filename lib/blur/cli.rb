# frozen_string_literal: true

require 'optparse'

require 'semantic_logger'

require_relative './config'

module Blur
  # Error that may occur when working with the CLI
  class CLIError < StandardError; end

  # Handles CLI interaction such as argument parsing and setting up a Blur
  # client.
  class CLI
    include SemanticLogger::Loggable

    # CLI options.
    class Options
      attr_accessor :config_path, :environment, :log_level, :log_format

      # @return [String] the default application enivronment
      DEFAULT_ENVIRONMENT = 'development'

      # @return [String] the default config file path
      DEFAULT_CONFIG_PATH = 'config.yaml'

      # @return [String] the default logging format
      DEFAULT_LOG_FORMAT = 'color'

      # @return [Array<String>] list of supported logging levels
      LOGGING_LEVELS = SemanticLogger::LEVELS

      # @return [Array<String>] list of supported logging formats
      LOGGING_FORMATS = %w[plain color json logfmt].freeze

      def initialize
        self.log_level = SemanticLogger.default_level
        self.log_format = DEFAULT_LOG_FORMAT
        self.config_path = DEFAULT_CONFIG_PATH
        self.environment = DEFAULT_ENVIRONMENT
      end

      def define_options(parser)
        parser.banner = "Usage: #{$PROGRAM_NAME} [OPTIONS]"

        parser.separator('')
        parser.separator('Options:')

        add_options(parser)
        add_log_options(parser)
        add_tail_options(parser)
      end

      private

      def add_options(parser)
        parser.on '-c', '--config=PATH', 'Set the configuration file' do |config_path|
          self.config_path = config_path
        end

        parser.on '-e', '--environment=ENV', 'Environment to run in' do |environment|
          self.environment = environment
        end

        parser.on '-r', '--require LIBRARY', 'Require the LIBRARY before running' do |lib|
          require lib
        end
      end

      def add_log_options(parser)
        logging_levels = LOGGING_LEVELS.join(', ')

        parser.on '-l', '--log-level=LEVEL', LOGGING_LEVELS, "Set logging levels (#{logging_levels})" do |log_level|
          self.log_level = log_level
        end

        logging_formats = LOGGING_FORMATS.join(', ')

        parser.on '-f', '--log-format=FORMAT', LOGGING_FORMATS, "Set logging format (#{logging_formats})" do |log_format|
          self.log_format = log_format
        end
      end

      def add_tail_options(parser)
        parser.on_tail('-V', '--version', 'Print Blur version and exit') do
          puts Blur::VERSION
          exit
        end

        parser.on_tail('-h', '--help', 'Show this message') do
          puts parser
          exit
        end
      end
    end

    def parse!(args = ARGV)
      @opts = Options.new
      @args = OptionParser.new do |parser|
        @opts.define_options(parser)
        parser.parse!(args)
      end
      @opts
    end

    def run
      parse!
      setup_logging

      logger.info "Blur #{Blur::VERSION}"
      load_config!
    end

    # Load and validate the config file.
    def load_config!
      config_path = File.expand_path @opts.config_path
      logger.debug "Loading configuration file `#{config_path}' .."

      raise CLIError, "Configuration file `#{config_path}' is not readable" unless File.readable?(config_path)

      @config = Config.load_file(config_path)
    end

    def setup_logging
      SemanticLogger.application = 'Blur'
      SemanticLogger.default_level = @opts.log_level
      SemanticLogger.environment = @opts.environment

      formatter = formatter_from_name(@opts.log_format)
      SemanticLogger.add_appender(io: $stderr, formatter: formatter)
    end

    def formatter_from_name(formatter_name, **args)
      formatter = case formatter_name.downcase
                  when 'plain' then SemanticLogger::Formatters::Default
                  when 'color' then SemanticLogger::Formatters::Color
                  when 'json' then SemanticLogger::Formatters::Json
                  when 'logfmt' then SemanticLogger::Formatters::Logfmt
                  else SemanticLogger::Formatters::Default
                  end

      formatter.new(**args)
    end

    attr_reader :opts
  end
end
