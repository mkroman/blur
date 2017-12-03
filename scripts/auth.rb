# encoding: utf-8

Blur::Script :auth do
  include Blur::Commands

  Author 'Mikkel Kroman <mk@maero.dk>'
  Version '0.1'
  Dependency :database, '~> 0.1'
  Description 'Simple authentication script'

  # Create the admin table if it doesn't exist.
  Sequel::Model.db.create_table? :admins do
    primary_key :id

    String :username, null: false
    String :nickname, null: false
    String :hostname, null: false

    DateTime :created_at
    DateTime :updated_at

    index [:nickname, :key], unique: true
  end

  class Admin
    plugin :timestamps
  end

  def authorized? user
    !Admin[nickname: user.nick, username: user.name, hostname: user.host].nil?
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
