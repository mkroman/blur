# encoding: utf-8

require 'json'
require 'open-uri'
require 'htmlentities'

Script :google do
  extend MessageParsing
  
  def command_google user, channel, args
    unless args
      channel.say format "Usage:\x0F .g <query>"
    end
    
    if result = search(args)
      channel.say format "#{HTMLEntities.decode_entities result[0]}\x0F - #{result[1]}"
    else
      channel.say format "No results"
    end 
  end
  
  def search query
    open "http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=#{URI.escape query}" do |response|
      results = JSON.parse(response.read)['responseData']['results']
      result = results.first
      
      result ? [result['titleNoFormatting'], result['unescapedUrl']] : nil
    end
  end
  
  def format message
    %{\x0310>\x0F \x02Google:\x02\x0310 #{message}}
  end
  
  alias :command_g :command_google
end