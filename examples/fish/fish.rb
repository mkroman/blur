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
     nickname: "fish",
     channels: %w{#channel #channel2},
     secure: true,

     # Set the fish keyphrase for our channel.
     fish: {
       "#channel"  => "changeme"
     }
  }]
}

# Start connecting to all our networks.
#
# @see Blur.connect
Blur.connect options do
  # Raised once for every network upon successful connection.
  on :connection_ready do |network|
    puts "Connection and established and I'm ready for action!"
  end

  # Raised when a message is sent from inside a channel.
  on :message do |user, channel, message|
    print Time.now.strftime("%I:%M:%S") + " "
    print "#{channel}:#{user}: "
    puts message

    if channel.encrypted?
      channel.say "I'm talking in code!"
    else
      channel.say ":-X"
    end
  end

  # Raised when a message is sent from a user outside of a channel.
  on :private_message do |user, message|
    user.say "Sorry, I do not handle personal business!"
  end
end
