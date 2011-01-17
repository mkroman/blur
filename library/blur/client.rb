# encoding: utf-8

require 'blur/handling'

module Blur
  class Client
    include Handling
    
    attr_accessor :options, :networks
    
    def initialize options
      @options   = options
      @networks  = []
      @callbacks = {}
      @connected = true
      
      @options[:networks].each do |options|
        @networks.<< Network.new options
      end
      
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
            puts "#{network} threw an exception: #{exception.class.name} #{exception.message} #{exception.backtrace.to_s}"
            
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
    end
    
    def catch name, &block
      (@callbacks[name] ||= []) << block
    end
    
  end
end
