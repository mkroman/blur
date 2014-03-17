# encoding: utf-8

module Blur
  class Script
    module DSL
      def self.included base
        base.send :attr_accessor, :__name
        base.send :attr_accessor, :__author
        base.send :attr_accessor, :__version
        base.send :attr_accessor, :__description
      end

      # Set the author.
      #
      # @example
      #   Author "John Doe <john.doe@gmail.com>"
      def Author *authors
        @__author = authors.join ', '
      end

      # Set the description.
      #
      # @example
      #   Description "This is an example script."
      def Description description
        @__description = description
      end

      # Set the version.
      #
      # @example
      #   Version "1.0"
      def Version version
        @__version = version
      end

      # @return the name of the script.
      def name; @__name end

      # @return the name of the author(s).
      def author; @__author end

      # @return the script version.
      def version; @__version end

      # @return the description.
      def description; @__description end

      alias_method :Authors, :Author
    end
  end
end