# encoding: utf-8

module Blur
  module Encryption
    # The +Encryption::Base64+ module differs from the original Base64
    # implementation. I'm not sure how exactly, perhaps the charset?
    #
    # I originally found the Ruby implementation of FiSH on a website where
    # it was graciously submitted by an anonymous user, since then I've
    # implemented it in a weechat script, and now I've refactored it for use in
    # Blur.
    #
    # @see http://maero.dk/pub/sources/weechat/ruby/autoload/fish.rb
    module Base64
      # The difference I suspect between the original Base64 implementation
      # and the one used in FiSH.
      Charset = "./0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

      # Decode a base64-encoded string.
      #
      # @return [String] Base64-decoded string.
      def self.decode string
        unless string.length % 12 == 0
          raise BadInputError, "input has to be a multiple of 12 characters."
        end

        String.new.tap do |buffer|
          j = -1
          
          while j < string.length - 1
            right, left = 0, 0

            6.times{|i| right |= Charset.index(string[j += 1]) << (i * 6) }
            6.times{|i| left  |= Charset.index(string[j += 1]) << (i * 6) }

            4.times do |i|
              buffer << ((left & (0xFF << ((3 - i) * 8))) >> ((3 - i) * 8)).chr
            end

            4.times do |i|
              buffer << ((right & (0xFF << ((3 - i) * 8))) >> ((3 - i) * 8)).chr
            end
          end
        end
      end

      # Encode a string-cipher.
      #
      # @return [String] Base64-encoded string.
      def self.encode string
        unless string.length % 8 == 0
          raise BadInputError, "input has to be a multiple of 8 characters."
        end

        left = 0
        right = 0
        decimals = [24, 16, 8, 0]

        String.new.tap do |buffer|
          string.each_block do |block|
            4.times{|i| left  += (block[i].ord << decimals[i]) }
            4.times{|i| right += (block[i+4].ord << decimals[i]) }

            6.times{|i| buffer << Charset[right & 0x3F].chr; right = right >> 6 }
            6.times{|i| buffer << Charset[left  & 0x3F].chr; left = left >> 6 }
          end
        end
      end
    end
  end
end