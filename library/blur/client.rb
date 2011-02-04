# encoding: utf-8

require 'blur/handling'

module Blur
  class Client
    include Handling
    
    attr_accessor :options, :scripts, :networks
    
    def initialize options
      @options   = options
      @scripts   = []
      @networks  = []
      @callbacks = {}
      @connected = true
      
      @networks = @options[:networks].map { |options| Network.new options }
      
      load_scripts
      trap 2, &method(:quit)
    end
    
    def connect
      networks = @networks.select { |network| not network.connected? }
      
      networks.each do |network|
        network.delegate = self
        network.connect
      end
      
      run_loop
    end
    
    def got_command network, command
      puts "<- #{network.inspect ^ :bold} | #{command}"
      name = :"got_#{command.name.downcase}"
      
      if respond_to? name
        __send__ name, network, command
      end
    end
    
    def load_scripts
      script_path = File.dirname $0
      
      Dir.glob("#{script_path}/scripts/*.rb").each do |path|
        script = Script.new path
        script.client = self
        
        @scripts << script
      end
    end
    
    def unload_scripts
      @scripts.each do |script|
        script.unload!
      end.clear
    end
    
    def quit signal
      @networks.each do |network|
        network.transmit :QUIT, "Got SIGINT?"
        network.transcieve
        network.disconnect
      end
      
      @connected = false
      unload_scripts
      
      exit 0
    end
    
  private
    
    def run_loop
      puts "Starting run loop ..."
      
      while @connected
        @networks.select(&:connected?).each do |network|
          begin
            network.transcieve
            sleep 0.05
          rescue StandardError => exception
            if network.connected?
              network.disconnect
              emit :connection_terminated, network
            end

            puts "#{"Network error" ^ :red} (#{exception.class.name}): #{exception.message}"
          end
        end
      end

      puts "Ended run loop ..."
    end
    
    def emit name, *args
      @callbacks[name].each do |callback|
        callback.call *args
      end if @callbacks[name]
      
      @scripts.each do |script|
        begin
          script.__send__ name, *args if script.respond_to? name
        rescue Exception => exception
          puts ("#{File.basename script.path}:#{exception.line}" ^ :bold) + ": #{"error:" ^ :red} #{exception.message}"
        end
      end
    end
    
    def catch name, &block
      (@callbacks[name] ||= []) << block
    end
    
  end
end
