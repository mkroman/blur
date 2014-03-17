# encoding: utf-8

require 'oj'
require 'multi_json'
require 'htmlentities'

Script :google_search, using: %w{http}, includes: [Commands] do
  Author "Mikkel Kroman <mk@uplink.io>"
  Version "0.1"
  Description "Search for stuff on google.com"

  # Script constants.
  SearchURI = "http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=%s&rsz=1"

  # Called when the script has been loaded.
  def loaded
    @decoder = HTMLEntities.new
  end

  # Register the .g/.google command.
  command %w{g google} do |user, channel, args|
    unless args
      return channel.say format "Usage:\x0F .g <query>"
    end

    search args do |title, uri|
      channel.say format "#{@decoder.decode title}\x0F - #{uri}"
    end    
  end
  
  # Search for something.
  #
  # @yields [Title, URL] or nil
  def search query
    search_uri = SearchURI % URI.escape(query)
    context = http.get search_uri, format: :json

    context.success do
      results = context.response['responseData']['results']

      if results.any?
        result = results.first

        yield result['titleNoFormatting'], result['unescapedUrl']
      end
    end

    context.error do
      yield nil
    end
  end
  
  def format message
    %{\x0310>\x0F \x02Google:\x02\x0310 #{message}}
  end
end
