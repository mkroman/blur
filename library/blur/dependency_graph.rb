# frozen_string_literal: true

module Blur
  module DependencyGraph
    class CircularDependencyError < StandardError; end

    class Node
      attr_accessor :key
      attr_accessor :edges

      def initialize edges = []
        @edges = edges
      end
    end

    class Graph
      attr_accessor :nodes

      def initialize nodes = {}
        @nodes = nodes
      end

      def add_dependency key, *dependencies
        node = @nodes[key] ||= Node.new

        dependencies.each do |dependency|
          @nodes[dependency] ||= Node.new
          node.edges << dependency
        end
      end

      def resolve node, resolved
        @nodes[node].edges.each do |edge|
          resolve edge, resolved unless resolved.include? edge
        end

        resolved << node
      end
    end
  end
end