# encoding: utf-8

require 'timeout'

module Pulse
  class DCC
    Duration = 150

    def initialize path
      @path = path
    end

    def listen
      client = nil

      TCPServer.open '0.0.0.0', 0 do |server|
        yield server.addr if block_given?

        begin
          timeout(Duration) { client = server.accept }
        rescue Timeout::Error
          server.close
        end

        each_chunk { |chunk| client.write chunk } if client
        client.close if client
      end
    end

    def each_chunk
      File.open @path, ?r do |file|
        yield file.readpartial 1024 until file.eof?
      end
    end

  end
end