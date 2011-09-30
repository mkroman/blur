# encoding: utf-8

module Blur
  # The +Encryption+ module extends the communication-functionality of
  # the client. It is intended to enable helpers but also core functionality
  # that encrypts the incoming and outgoing data of Blur.
  #
  # Encryption modules are not loaded into the VM until it's required.
  module Encryption
    # Indicates that user-input (a channel user message, e.g.) is in invalid
    # format to a certain encryption algorithm.
    class BadInputError < StandardError; end

    autoload :FiSH,   "blur/encryption/fish"
    autoload :Base64, "blur/encryption/base64"
  end
end