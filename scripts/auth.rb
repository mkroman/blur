# encoding: utf-8

Blur::Script :auth do
  Author 'Mikkel Kroman <mk@maero.dk>'
  Version '0.1'
  Description 'Simple authentication script'

  include Blur::Commands

  def authorized? user
    @config[:admins].include? "#{user.nick}!#{user.name}@#{user.host}"
  end

  command! '.reload' do |user, channel, args|
    if authorized? user
      _client_ref.reload!

      channel.say "\x0310> Configuration and scripts reloaded."
    else
      channel.say "\x0310> You're not authorized to use this command."
    end
  end
end
