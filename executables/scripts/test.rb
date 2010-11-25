# encoding: utf-8

Script :test, [1, 0], 'Mikkel Kroman' do
  def loaded
    cache[:messages] = []
  end

  def message user, channel, line
    if line.starts_with? '!print'
      cache[:messages].each do |message|
        channel.say message
      end
    else
      cache[:messages] << line
    end
  end
end
