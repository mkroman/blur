# encoding: utf-8

# TODO: Add proper support for private messages

Script :auth do
  extend MessageParsing
  
  def loaded
    cache[:admins] = %w{mk!mk@uplink.io}
  end
  
  def command_reload user, channel, args
    if authorized? user
      @client.unload_scripts
      @client.load_scripts
    else
      channel.say "\x0310> You are not authorized to use this command."
    end
  end
  
private

  def authorized? user
    cache[:admins].include? "#{user.nick}!#{user.name}@#{user.host}"
  end
end
