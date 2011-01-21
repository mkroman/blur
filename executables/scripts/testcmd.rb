# encoding: utf-8

Script :test do
  extend MessageParsing
  
  def command_topic user, channel, args
    channel.say "This channels topic: #{channel.topic}"
  end

  def command_whatismyattributes user, channel, args
    channel.say ".operator? = #{user.operator?} .owner? = #{user.owner?} .admin? = #{user.admin?} .half_operator? = #{user.half_operator?} .voice? = #{user.voice?}"
  end

  def command_channel user, channel, args
    channel.say "> #{channel.name} - users: #{channel.users.count} - topic: #{channel.topic} - modes: #{channel.modes}"
  end
end
