# encoding: utf-8

require 'pulse/handling'

module Pulse
  class Client
    include Handling

    attr_accessor :options, :networks

    def initialize options
      @options  = options
      @networks = []

      @options[:networks].each do |network|
        host, port = network.split ?:
        @networks.<< Network.new host, (port.to_i or 6667)
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
      puts "<< #{network}: #{command}"
    end

  private
    
    def run_loop
      puts "Starting run loop …"
      pp @networks

      while (networks = @networks.select(&:connected?)).any?
        networks.each &:transcieve
      end

      puts "Finished run loop …"
    end
  end
end
