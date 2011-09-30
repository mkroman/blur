# encoding: utf-8

require 'crypt/blowfish'

module Blur
  module Encryption
    class FiSH
      BlockSize = 8

      def initialize keyphrase
        @blowfish = Crypt::Blowfish.new keyphrase
      end

      def encrypt string
        String.new.tap do |buffer|
          nullpad(string).each_block do |block|
            chunk = @blowfish.encrypt_block block
            buffer.concat Base64.encode chunk
          end
        end
      end

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

      def nullpad string
        length = string.length + BlockSize - string.length % BlockSize
        string.ljust length, ?\0
      end
    end
  end
end