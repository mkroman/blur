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
      puts "#{command.name.inspect}"

      if command.name == "376" or command.name == "422"
        network.transmit :JOIN, "#warsow.na"
      elsif command.name == "PING"
        network.transmit :PONG, command[0]
      end

      puts "<< #{network}: #{command}"
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
  end
end
