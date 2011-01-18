# encoding: utf-8

# TODO: Add proper support for private messages

Script :auth do
  def loaded
    cache[:admins] ||= %w{mk!mk@uplink.io}
  end
  
  def message user, channel, line
    return unless line.starts_with? ".reload"
    
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