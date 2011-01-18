# encoding: utf-8

require 'json'
require 'open-uri'
require 'htmlentities'

Script :google do
  def message user, channel, line
    return unless line.starts_with? "!g"
    
    command, query = line.split $;, 2
    
    unless query
      channel.say format "Usage:\x0F .g <query>"
    end
    
    if result = search(query)
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
end