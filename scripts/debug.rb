# encoding: utf-8

Blur::Script :debug do
  include Blur::Commands

  command! '.debug' do |user, channel, args|
    channel.say "\x0310> Channel: #{channel.inspect}"
    channel.say "\x0310> We share the following channels: #{user.channels.map(&:name)}"
  end
end
