# frozen_string_literal: true

module Blur
  class Network
    # ISupport class that enables servers to announce what they support.
    #
    # @see https://tools.ietf.org/html/draft-brocklesby-irc-isupport-03
    class ISupport < Hash
      # Return the network reference.
      attr_accessor :network

      # ISUPPORT parameters which should always be casted to numeric values.
      NUMERIC_PARAMS = %w[CHANNELLEN MODES NICKLEN KICKLEN TOPICLEN AWAYLEN
                          MAXCHANNELS MAXBANS MAXPARA MAXTARGETS].freeze

      # Our parsers for parameters that require special treatment.
      PARSERS = {
        # CHANLIMIT=pfx:num[,pfx:num,...]
        #
        # This parameter specifies the maximum number of channels that a client
        # may join.  The value is a series of "pfx:num" pairs, where 'pfx'
        # refers to one or more channel prefix characters (as specified in
        # CHANTYPES), and 'num' indicates how many of these types of channel
        # the client may join in total. If there is no limit to the number of
        # certain channel type(s) a client may join, the limit should be
        # specified as the empty string, for example "#:".
        %w[CHANLIMIT] => lambda do |value|
          {}.tap do |result|
            params = value.split(',')
            mappings = params.map { |param| param.split ':' }

            mappings.each do |prefixes, limit|
              prefixes.each_char do |prefix|
                result[prefix] = limit ? limit.to_i : Float::INFINITY
              end
            end
          end
        end,

        # PREFIX=[(modes)prefixes]
        #
        #
        # The PREFIX parameter specifies a list of channel status flags (the
        # "modes" section) that clients may have on channels, followed by a
        # mapping to the equivalent channel status flags ("prefixes"), which
        # are used in NAMES and WHO replies.  There is a one to one mapping
        # between each mode and prefix.
        #
        # The order of the modes is from that which gives most privileges on
        #  the channel, to that which gives the least.
        %w[PREFIX] => lambda do |value|
          {}.tap do |result|
            match = value.match(/^\((.+)\)(.*)/)

            if match
              modes, prefix = match[1..2]

              modes.chars.each_with_index do |char, index|
                result[char] = prefix[index]
              end
            end
          end
        end,

        # CHANMODES=A,B,C,D
        #
        # The CHANMODES token specifies the modes that may be set on a channel.
        # These modes are split into four categories, as follows:
        #
        # o  Type A: Modes that add or remove an address to or from a list.
        #    These modes always take a parameter when sent by the server to a
        #    client; when sent by a client, they may be specified without a
        #    parameter, which requests the server to display the current
        #    contents of the corresponding list on the channel to the client.
        # o  Type B: Modes that change a setting on the channel.  These modes
        #    always take a parameter.
        # o  Type C: Modes that change a setting on the channel. These modes
        #    take a parameter only when set; the parameter is absent when the
        #    mode is removed both in the client's and server's MODE command.
        # o  Type D: Modes that change a setting on the channel. These modes
        #    never take a parameter.
        %w[CHANMODES] => lambda do |value|
          {}.tap do |r|
            r['A'], r['B'], r['C'], r['D'] = value.split(',').map(&:chars)
          end
        end,

        # Cast known params that are numeric, to a numeric value.
        NUMERIC_PARAMS => lambda do |value|
          value.to_i
        end
      }.freeze

      # Initialize a new ISupport with a network reference.
      #
      # @param network [Network] The parent network.
      def initialize(network)
        super

        @network = network

        # Set default ISUPPORT values.
        #
        # @see
        # https://tools.ietf.org/html/draft-brocklesby-irc-isupport-03#appendix-A
        self['MODES']       = 3
        self['PREFIX']      = { 'o' => '@', 'v' => '+' }
        self['KICKLEN']     = 200
        self['NICKLEN']     = 9
        self['MAXLIST']     = { '#' => Float::INFINITY, '&' => Float::INFINITY }
        self['TOPICLEN']    = 200
        self['CHANMODES']   = {}
        self['CHANTYPES']   = %w[# &]
        self['CHANLIMIT']   = { '#' => Float::INFINITY, '&' => Float::INFINITY }
        self['CHANNELLEN']  = 200
        self['CASEMAPPING'] = 'rfc1459'
      end

      # Parse a list of parameters to see what the server supports.
      #
      # @param parameters [Array] The list of parameters.
      def parse(*params)
        params.each do |parameter|
          name, value = parameter.split('=')

          if value
            _, parser = PARSERS.find { |key, _value| key.include?(name) }

            self[name] = parser.nil? ? value : parser.call(value)
          else
            self[name] = true
          end
        end
      end
    end
  end
end
