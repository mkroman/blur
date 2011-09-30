# encoding: utf-8

module Blur
  module Encryption
    class BadInputError < StandardError; end

    autoload :FiSH,   "blur/encryption/fish"
    autoload :Base64, "blur/encryption/base64"
  end
end