# encoding: utf-8

require 'crypt/blowfish'

module Blur
  module Encryption
    # The +FiSH+ algorithm is a combination of Base64 encoding
    # and the blowfish encryption.
    #
    # Shared text messages are prepended by "++OK+", an older implementation
    # prepends it with "+mcps+" - Blur drops support for that implementation.
    #
    # There's multiple client-implementations available on the official FiSH
    # homepage.
    #
    # == DH1080 Key exchange
    # The newer FiSH implementation introduces a 1080bit Diffie-Hellman 
    # key-exchange mechanism.
    #
    # Blur does currently not support key exchanges.
    class FiSH
      # The standard FiSH block-size.
      BlockSize = 8

      # @return [String] the blowfish salt-key.
      attr_accessor :keyphrase      

      # Change the keyphrase and instantiate a new blowfish object.
      def keyphrase= keyphrase
        @keyphrase = keyphrase
        @blowfish = Crypt::Blowfish.new @keyphrase
      end

      # Instantiate a new fish-encryption object.
      def initialize keyphrase
        @keyphrase = keyphrase
        @blowfish = Crypt::Blowfish.new keyphrase
      end

      # Encrypt an input string using the keyphrase stored in the +@blowfish+
      # object.
      #
      # @return [String] the encrypted string.
      def encrypt string
        String.new.tap do |buffer|
          nullpad(string).each_block do |block|
            chunk = @blowfish.encrypt_block block
            buffer.concat Base64.encode chunk
          end
        end
      end

      # Decrypt an input string using the keyphrase stored in the +@blowfish+
      # object.
      #
      # @return [String] the decrypted string.
      def decrypt string
        unless string.length % 12 == 0
          raise BadInputError, "input has to be a multiple of 12 characters."
        end
          
        String.new.tap do |buffer|
          string.each_block 12 do |block|
            chunk = @blowfish.decrypt_block Base64.decode block
            buffer.concat chunk
          end
        end.rstrip
      end
      
    private
      # Fill up the last block with null-bytes until it's a multiple of 8.
      #
      # @return [String] the nullpadded string.
      def nullpad string
        length = string.length + BlockSize - string.length % BlockSize
        string.ljust length, ?\0
      end
    end
  end
end