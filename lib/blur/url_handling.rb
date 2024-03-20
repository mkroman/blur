# frozen_string_literal: true

require 'addressable/uri'

module Blur
  module URLHandling
    # Pattern of schemes that make up extractable URLs.
    ACCEPTED_SCHEMES = /\Ahttps?\z/i

    # The URL registry is used for registering URL matching conditions and their
    # respective handlers.
    class URLRegistry
      # A number that is incremented and used to identify the registered handler
      # method.
      attr_reader :index

      def initialize
        @index = -1
        @handlers = { hosts: {} }
      end

      # Register a URL handler.
      def register(*args, &block)
        @index += 1

        args.each do |arg|
          case arg
          when String then register_handler(host: arg, &block)
          when Hash then register_handler(arg, &block)
          end
        end

        @index
      end

      # Registers the criteria for the handler and returns a unique method id.
      def register_handler(criteria, &)
        host = criteria[:host]

        return unless host

        (@handlers[:hosts][host] ||= []) << @index

        @index
      end

      def handler_method_ids_for(url)
        @handlers[:hosts][url.host]
      end
    end

    # Helper methods that are added in the script when the URLHandling module is
    # included.
    module ClassMethods
      def url_registry
        class_variable_get(:@@url_registry)
      end

      def url_registry=(registry)
        class_variable_set(:@@url_registry, registry)
      end

      def register_url!(*args, &block)
        id = url_registry.register(*args)
        define_method(:"_url_handler_#{id}", &block)
      end
    end

    def self.included(klass)
      klass.extend(ClassMethods)
      klass.url_registry = URLRegistry.new

      handler = lambda do |script, user, channel, line, _tags|
        return unless (urls = URLHandling.extract_urls(line))

        urls.each do |url|
          method_ids = klass.url_registry.handler_method_ids_for(url)

          next unless method_ids&.any?

          method_ids.each do |id|
            script.__send__(:"_url_handler_#{id}", user, channel, url)
          end
        end
      end

      klass.register!(message: handler)
    end

    def self.extract_urls(text)
      words = text.to_s.split.filter { |word| word.start_with?(/http/i) }
      words.map do |word|
        url = Addressable::URI.parse(word)
        url.normalize if url.scheme =~ ACCEPTED_SCHEMES
      end.compact
    end
  end
end
