# encoding: utf-8

require 'pulse/handling'

module Pulse
  class Client
    include Handling

    attr_accessor :options, :networks

    def initialize options
      @options   = options
      @networks  = []
      @callbacks = {}

      @options[:networks].each do |network|
        host, port = network.split ?:
        @networks.<< Network.new host, (port ? port.to_i : 6667)
      end
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

  private
    
    def run_loop
      puts "Starting run loop …"
      pp @networks

      begin
        while (networks = @networks.select(&:connected?)).any?
          networks.each &:transcieve
        end
      rescue Errno::ECONNRESET
        puts "Connection reset .."
      end

      puts "Finished run loop …"
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
