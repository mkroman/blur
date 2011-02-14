# encoding: utf-8
#
Script :health do
  extend MessageParsing

  def command_health user, channel, args
    channel.say format "Memory usage:\x0F #{memory_usage} MB\x0310 Threads:\x0F #{Thread.list.length}\x0310 Scripts:\x0F #{@client.scripts.count}\x0310"
  end

  def format message
    %{\x0310>\x0F\x02 Health:\x02\x0310 #{message}}
  end

private

  def memory_usage
    (%x{ps -o rss= -p #{Process.pid}}.to_f / 1024.0).round
  end
end
