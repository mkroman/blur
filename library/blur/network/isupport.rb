# encoding: utf-8

module Blur
  class Network
    # ISupport class that enables servers to announce what they support.
    # 
    # @see https://tools.ietf.org/html/draft-brocklesby-irc-isupport-03
    class ISupport
      # Return the network reference.
      attr_accessor :network

      # Return the isupport parameters.
      attr_accessor :parameters

      # Initialize a new ISupport with a network reference.
      # 
      # @param network [Network] The parent network.
      def initialize network
        @network = network
        @chanlimit = {}
        @parameters = {}
      end

      # Synchronize the current list of support parameters with the given
      # input parameters.
      #
      # @param parameters [String] The list of parameters.
      def synchronize! *parameters
        parameters.each do |parameter|
          key, value = parse_parameter parameter

          if value
            assign key, value
          else
            @parameters[key] = nil
          end
        end
      end

    protected

      # Split a parameter into a key and value.
      #
      # @return [String, String] key and value.
      def parse_parameter parameter
        if parameter.to_s =~ /([A-Z]+)(=.+)?/
          return $1, $2 && $2[1..-1]
        end
      end
    end
  end
end
