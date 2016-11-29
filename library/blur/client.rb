# encoding: utf-8

require 'blur/handling'

module Blur
  # The +Client+ class is the controller of the low-level access.
  #
  # It stores networks, scripts and callbacks, and is also encharge of
  # distributing the incoming commands to the right networks and scripts.
  class Client
    include Callbacks
    include Handling, Logging

    # Client error.
    Error = Class.new StandardError

    # The default environment.
    ENVIRONMENT = ENV['BLUR_ENV'] || 'development'

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

    attr_accessor :verbose

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
      @environment = options[:environment]
      @verbose = options[:verbose] == true

      load_config!

      networks = @config['blur']['networks']

      if networks and networks.any?
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
          log.error "#{exception.message ^ :bold} on line #{exception.line.to_s ^ :bold}"
          puts exception.backtrace.join "\n"
        end
      end
    end
    
    # Is called when a command have been received and parsed, this distributes
    # the command to the loader, which then further distributes it to events
    # and scripts.
    #
    # @param [Network] network the network that received the command.
    # @param [Network::Command] command the received command.
    def got_command network, command
      if @verbose
        log "#{'←' ^ :green} #{command.name.to_s.ljust(8, ' ') ^ :light_gray} #{command.params.map(&:inspect).join ' '}"
      end
      name = :"got_#{command.name.downcase}"

      if respond_to? name
        __send__ name, network, command
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
        network.transmit :QUIT, "Got SIGINT?"
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
      scripts_cache_dir = File.expand_path @config['blur']['cache_dir']

      Dir.glob File.join(scripts_dir, '*.rb') do |file|
        begin
          load file, true
        rescue Exception => e
          STDERR.puts "The script `#{file}' failed to load"
          STDERR.puts "#{e.class}: #{e.message}"
          STDERR.puts
          STDERR.puts 'Backtrace:', '---', e.backtrace
        end
      end

      scripts_config = @config['scripts']

      Blur.scripts.each do |name, superscript|
        script = superscript.allocate
        script.cache = ScriptCache.load name, scripts_cache_dir
        script.config = scripts_config.fetch name, {}
        script._client_ref = self
        script.send :initialize

        @scripts[name] = script
      end

      emit :scripts_loaded
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
        raise Error, "No configuration found for specified environment `#{@environment}'"
      end
    end
  end
end
