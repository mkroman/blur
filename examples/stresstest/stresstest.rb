#!/usr/bin/env ruby
# encoding: utf-8

$:.unshift File.dirname(__FILE__) + '/../../library'
require 'blur'

# Basic options, we're going to fill this with networks.
#
# @see Blur::Network.new
# @see Blur::Client.new
options = {
  networks: []
}

# Populate the networkslist with 1000 networks.
# Please do not use this as an attack on remote IRCd's - they have an anti-flood
# system anyway.
#
# If you'd like to test it, you're welcome to do so on uplink.io, there is no
# anti-flood enabled.
1000.times do |i|
  options[:networks].push({
    hostname: "uplink.io",
    nickname: "clone-#{i.to_s 36}",
    channels: %w{#stresstest},
      secure: true,
        port: 6697
  })
end

# Start connecting to all our networks.
#
# @see Blur.connect
Blur.connect options do
  # …
end