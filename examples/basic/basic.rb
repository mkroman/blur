#!/usr/bin/env ruby
# encoding: utf-8

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
  catch :connection_ready do |network|
    puts "Connection and established and I'm ready for action!"
  end

  # Raised when a message is sent from inside a channel.
  catch :message do |user, channel, message|
    print Time.now.strftime("%I:%M:%S") + " "
    print "#{channel}:#{user}: "
    puts message
  end

  # Raised when a message is sent from a user outside of a channel.
  catch :private_message do |user, message|
    user.say "Sorry, I do not handle personal business!"
  end
end