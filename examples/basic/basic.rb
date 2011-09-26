#!/usr/bin/env ruby
# encoding: utf-8

require 'blur'

options = {
  networks: [{
     hostname: "uplink.io",
     nickname: "basic",
     channels: %w{#channel #channel2}
  }]
}

Blur.connect options do
  catch :connection_ready do |network|
    puts "Connection and established and I'm ready for action!"
  end

  catch :message do |user, channel, message|
    print Time.now.strftime("%I:%M:%S") + " "
    print "#{channel}:#{user}: "
    puts message
  end

  catch :private_message do |user, message|
    user.say "Sorry, I do not handle personal business!"
  end
end