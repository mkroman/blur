# encoding: utf-8

Script :test do
  extend MessageParsing
  
  def command_topic user, channel, args
    channel.say "This channels topic: #{channel.topic}"
  end
end