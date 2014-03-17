# encoding: utf-8

require 'em-http-request'
require 'em-http/middleware/json_response'

# The +http extension+ is a simple event-driven HTTP interface for scripts
#
# @example
#   context = http.get "http://www.google.com/"
#
#   context.success do
#     puts "#{context.response}"
#   end
#   
#   context.error do
#     puts "Connection failed"
#   end
Extension :http do
  Author "Mikkel Kroman <mk@uplink.io>"
  Version "0.1"
  Description "Provides a simple event-driven HTTP interface for scripts"

  # +HTTPContext+ is a DSL wrapper around em-http.
  class HTTPContext
    # Initialize the wrapper.
    def initialize client
      @client = client
    end

    # Set the request callback proc.
    def success &block
      @client.callback &block
    end

    # Set the request error proc.
    def error &block
      @client.errback &block
    end

    # @returns The HTTP response.
    def response
      @client.response
    end
  end

  # Return a new http context with a newly initiated get request.
  #
  # @option options [optional, Symbol] :format The response format, can be :json.
  def get uri, *params, &block
    options    = params.last.is_a?(Hash) ? params.pop : {}
    connection = EM::HttpRequest.new uri

    case options[:format]
    when :json
      connection.use EM::Middleware::JSONResponse
    end

    request = connection.get *params

    HTTPContext.new(request).instance_eval &block
  end

  # Return a new http context with a newly initiated post request.
  #
  # @option params [optional, String] :body The POST data.
  # @option options [optional, Symbol] :format The response format, can be :json.
  def post uri, *params, &block
    options    = params.last.is_a?(Hash) ? params.pop : {}
    connection = EM::HttpRequest.new uri

    case options[:format]
    when :json
      connection.use EM::Middleware::JSONResponse
    end

    request = connection.post *params

    HTTPContext.new(request).instance_eval &block
  end
end