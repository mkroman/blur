#!/usr/bin/env ruby
# encoding: utf-8

$:.unshift File.dirname(__FILE__) + '/../../library'
require 'blur'

# Set our options.
#
# @see Blur::Network.new
# @see Blur::Client.new
options = {
  networks: [{
     hostname: "uplink.io",
     nickname: "basic",
     channels: %w{#channel #channel2}
  }]
}

# Start connecting to all our networks.
#
# @see Blur.connect
Blur.connect options do
  # Raised once for every network upon successful connection.
  on :connection_ready do |network|
    log.info "Connection established and I'm ready for action!"
  end
end
