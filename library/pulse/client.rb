# encoding: utf-8

module Pulse
  class Client
    def connected?; @networks.select(&:connected?).any? end

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

  private
    
    def run_loop
      puts "Starting run loop …"

      while connected?
        @networks.select(&:connected?).each &:transcieve
      end

      puts "Finished run loop …"
    end
  end
end
