# encoding: utf-8

module Blur
  module Encryption
    module Base64
      Charset = "./0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

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