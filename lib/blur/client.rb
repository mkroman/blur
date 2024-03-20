# frozen_string_literal: true

require_relative 'handling'

module Blur
  # The +Client+ class is the controller of the low-level access.
  #
  # It stores networks, scripts and callbacks, and is also encharge of
  # distributing the incoming commands to the right networks and scripts.
  class Client
    include SemanticLogger::Loggable

    include Callbacks
    include Handling

    # The default environment.
    DEFAULT_ENVIRONMENT = ENV['BLUR_ENV'] || 'development'

    # @return [Array] a list of instantiated networks.
    attr_accessor :networks
    # @return [Hash] client configuration.
    attr_accessor :config
    # @return [Hash] initialized scripts.
    attr_accessor :scripts
    # @return [String] the path to the currently used config file.
    attr_accessor :config_path

    # Instantiates the client, stores the options, instantiates the networks
    # and then loads available scripts.
    #
    # @param [String] config_path the path the client configuration in yaml format
    # @param [String] environment the application environment to use
    def initialize(config_path = DEFAULT_CONFIG_PATH, environment = DEFAULT_ENVIRONMENT)
      @scripts = {}
      @networks = []
      @config_path = config_path
      @environment = environment

      load_config!
      load_scripts!

      Signal.trap('INT', &method(:quit))
    end

    # Connect to each network available that is not already connected, then
    # proceed to start the run-loop.
    def connect
      networks = @config.networks

      if networks&.any?
        @networks = []

        networks.each do |network_options|
          logger.trace "options:", network_options
          @networks << Network.new(network_options, self)
        end
      end

      logger.trace "networks:", @networks

      Async do |task|
        @networks.each { |network| network.connect(task) }
      end
    end

    # Is called when a command have been received and parsed, this distributes
    # the command to the loader, which then further distributes it to events
    # and scripts.
    #
    # @param [Network] network the network that received the command.
    # @param [Network::Command] command the received command.
    def got_message(network, message)
      puts "← #{message.command.to_s.ljust(8, ' ')} #{message.parameters.map(&:inspect).join ' '}" if @verbose

      name = :"got_#{message.command.downcase}"
      __send__(name, network, message) if respond_to?(name)
    end

    # Called when a network connection is either closed, or terminated.
    def network_connection_closed(network)
      emit(:connection_close, network)
    end

    # Try to gracefully disconnect from each network, unload all scripts and
    # exit properly.
    #
    # @param [optional, Symbol] signal The signal received by the system, if any.
    def quit(_signal = :SIGINT)
      @networks.each do |network|
        network.transmit(:QUIT, 'Got SIGINT?')
        network.disconnect
      end
    end

    # Reloads configuration file and scripts.
    def reload!
      unload_scripts!
      load_config!
      load_scripts!

      yield if block_given?
    end

    # Loads all scripts in the script directory.
    def load_scripts!
      scripts_dir = File.expand_path(@config.scripts_dir)
      logger.debug("Loading scripts from #{scripts_dir.inspect}")

      script_file_paths = Dir.glob(File.join(scripts_dir, '*.rb'))
      logger.trace("Script directory contains #{script_file_paths.count} scripts")

      # Sort the script file paths by file name so they load by alphabetical
      # order.
      #
      # This will make it possible to create a script called '10_database.rb'
      # which will be loaded before '20_settings.rb' and non-numeric prefixes
      # will be loaded after that.
      script_file_paths = script_file_paths.sort do |a, b|
        File.basename(a) <=> File.basename(b)
      end

      script_file_paths.each { |script_path| load_script_file(script_path) }

      initialize_superscripts

      emit(:scripts_loaded)
    end

    # Loads the given +file_path+ as a Ruby script, wrapping it in an anonymous
    # module to protect our global namespace.
    #
    # @param [String] file_path the path to the ruby script.
    #
    # @raise [Exception] if there was any problems loading the file
    def load_script_file(file_path)
      logger.trace("Loading script #{file_path}")

      load file_path, true
    rescue Exception => e # rubocop:disable Lint/RescueException
      logger.error("The script `#{file_path}' failed to load", e)
    end

    # Instantiates each +SuperScript+ in the +Blur.scripts+ list by manually
    # allocating an instance and calling #initialize on it, then the instance is
    # stored in +Client#scripts+.
    #
    # @raise [Exception] any exception that might occur in any scripts'
    #   #initialize method.
    def initialize_superscripts
      scripts_config = @config.scripts
      scripts_cache_dir = File.expand_path(@config.cache_dir)

      Blur.scripts.each do |name, superscript|
        script = superscript.allocate
        script.cache = ScriptCache.load(name, scripts_cache_dir)
        script.config = scripts_config.fetch(name, {})
        script._client_ref = self
        script.send(:initialize)

        @scripts[name] = script
      end
    end

    # Unloads initialized scripts and superscripts.
    #
    # This method will call #unloaded on the instance of each loaded script to
    # give it a chance to clean up any resources.
    def unload_scripts!
      @scripts.each_value do |script|
        script.__send__(:unloaded) if script.respond_to?(:unloaded)
      end.clear

      Blur.reset_scripts!
    end

    private

    # Load the user-specified configuration file.
    #
    # @returns true on success, false otherwise.
    def load_config!
      @config = Config.load_file(@config_path)

      emit(:config_load)
    end
  end
end
