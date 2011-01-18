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
      
      @options[:networks].each do |options|
        @networks.<< Network.new options
      end
      
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
      puts "<- \e[1m#{network}\e[0m | #{command}"
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
      
      exit 0
    end
    
  private
    
    def run_loop
      puts "Starting run loop ..."
      
      while @connected
        @networks.each do |network|
          begin
            network.transcieve
            sleep 0.05
          rescue StandardError => exception
            puts "\e[1m\e[31merror:\e[39m #{exception.message}\e[0m"
            
            network.disconnect if network.connected?
            @networks.delete network
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
          puts "\e[1m#{File.basename script.path}:#{exception.line}: \e[31merror:\e[39m #{exception.message}\e[0m"
        end
      end
    end
    
    def catch name, &block
      (@callbacks[name] ||= []) << block
    end
    
  end
end
