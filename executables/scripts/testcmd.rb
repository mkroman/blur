# encoding: utf-8

Script :test do
  extend MessageParsing
  
  def private_message user, message
    user.say "#{message} selv!"
  end

end
