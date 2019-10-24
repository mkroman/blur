# encoding: utf-8

module Blur
  # The +Client+ class is the controller of the low-level access.
  #
  # It stores networks, scripts and callbacks, and is also encharge of
  # distributing the incoming commands to the right networks and scripts.
  class Client
    include Callbacks
    include Logging

    # The default environment.
    ENVIRONMENT = ENV['BLUR_ENV'] || 'development'.freeze

    # The default configuration.
    DEFAULT_CONFIG = {
      'blur' => {
        'cache_dir' => 'cache/',
        'scripts_dir' => 'scripts/',
        'networks' => []
      },
      'scripts' => {},
    }.freeze
    
    # @return [Array] a list of instantiated networks.
    attr_accessor :networks
    # @return [Hash] client configuration.
    attr_accessor :config
    # @return [Hash] initialized scripts.
    attr_accessor :scripts
    # @return [Boolean] whether verbose logging is enabled.
    attr_accessor :verbose
    # @return [String] the path to the currently used config file.
    attr_accessor :config_path

    # Instantiates the client, stores the options, instantiates the networks
    # and then loads available scripts.
    #
    # @param [Hash] options the options for the client.
    # @option options [String] :config_path path to a configuration file.
    # @option options [String] :environment the client environment.
    def initialize options = {}
      @scripts = {}
      @networks = []
      @config_path = options[:config_path]
      @environment = options[:environment] || ENVIRONMENT
      @verbose = options[:verbose] == true

      unless @config_path
        raise ConfigError, 'missing config file path in :config_path option'
      end

      load_config!

      networks = @config['blur']['networks']

      if networks&.any?
        networks.each do |network_options|
          @networks.<< Network.new network_options, self
        end
      end

      trap 2, &method(:quit)
    end
    
    # Connect to each network available that is not already connected, then
    # proceed to start the run-loop.
    def connect
      networks = @networks.reject &:connected?
      
      EventMachine.run do
        load_scripts!
        networks.each &:connect

        EventMachine.error_handler do |exception|
          message_pattern = /^.*?:(\d+):/
          backtrace = exception.backtrace.first
          error_line = backtrace.match(message_pattern)[1].to_i + 1

          log.error "#{exception.message ^ :bold} on line #{error_line.to_s ^ :bold}"
          puts exception.backtrace.join "\n"
        end
      end
    end
    
    # Called when a network connection is either closed, or terminated.
    def network_connection_closed network
      emit :connection_close, network
    end
    
    # Try to gracefully disconnect from each network, unload all scripts and
    # exit properly.
    #
    # @param [optional, Symbol] signal The signal received by the system, if any.
    def quit signal = :SIGINT
      @networks.each do |network|
        network.transmit :QUIT, 'Got SIGINT?'
        network.disconnect
      end

      EventMachine.stop
    end

    # Reloads configuration file and scripts.
    def reload!
      EM.schedule do
        unload_scripts!
        load_config!
        load_scripts!

        yield if block_given?
      end
    end

    # Loads all scripts in the script directory.
    def load_scripts!
      scripts_dir = File.expand_path @config['blur']['scripts_dir']
      script_file_paths = Dir.glob File.join scripts_dir, '*.rb'

      # Sort the script file paths by file name so they load by alphabetical
      # order.
      #
      # This will make it possible to create a script called '10_database.rb'
      # which will be loaded before '20_settings.rb' and non-numeric prefixes
      # will be loaded after that.
      script_file_paths = script_file_paths.sort do |a, b|
        File.basename(a) <=> File.basename(b)
      end

      script_file_paths.each { |script_path| load_script_file script_path }

      initialize_superscripts

      emit :scripts_loaded
    end

    # Loads the given +file_path+ as a Ruby script, wrapping it in an anonymous
    # module to protect our global namespace.
    #
    # @param [String] file_path the path to the ruby script.
    #
    # @raise [Exception] if there was any problems loading the file
    def load_script_file file_path
      load file_path, true
    rescue Exception => exception
      warn "The script `#{file_path}' failed to load"
      warn "#{exception.class}: #{exception.message}"
      warn ''
      warn 'Backtrace:', '---', exception.backtrace
    end

    # Instantiates each +SuperScript+ in the +Blur.scripts+ list by manually
    # allocating an instance and calling #initialize on it, then the instance is
    # stored in +Client#scripts+.
    #
    # @raise [Exception] any exception that might occur in any scripts'
    #   #initialize method.
    def initialize_superscripts
      scripts_config = @config['scripts']
      scripts_cache_dir = File.expand_path @config['blur']['cache_dir']

      Blur.scripts.each do |name, superscript|
        script = superscript.allocate
        script.cache = ScriptCache.load name, scripts_cache_dir
        script.config = scripts_config.fetch name, {}
        script._client_ref = self
        script.send :initialize

        @scripts[name] = script
      end
    end

    # Unloads initialized scripts and superscripts.
    #
    # This method will call #unloaded on the instance of each loaded script to
    # give it a chance to clean up any resources.
    def unload_scripts!
      @scripts.each do |name, script|
        script.__send__ :unloaded if script.respond_to? :unloaded
      end.clear

      Blur.reset_scripts!
    end

    private

    # Load the user-specified configuration file.
    #
    # @returns true on success, false otherwise.
    def load_config!
      config = YAML.load_file @config_path

      if config.key? @environment
        @config = config[@environment]
        @config.deeper_merge! DEFAULT_CONFIG

        emit :config_load
      else
        raise ClientError, "No configuration found for specified environment `#{@environment}'"
      end
    end
  end
end
