# encoding: utf-8

Script :test do
  def loaded
    puts "script was loaded"
    p cache
    p cache[:test]
    
    cache[:test] = "hi"
    cache.save
  end
  
  def message user, channel, line
    channel.say "this is a test script"
  end
end