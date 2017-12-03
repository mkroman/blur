# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Blur::DependencyGraph::Graph do
  describe '.new' do
    it 'should not have any nodes' do
      expect(subject.nodes).to be_empty
    end
  end

  describe '#add_dependency' do
    it 'should add the dependency to the list of nodes' do
      subject.add_dependency :dependency_a
      subject.add_dependency :dependency_b, :dependency_a

      expect(subject.nodes).to include :dependency_a, :dependency_b
    end
  end

  describe '#resolve' do
    it 'should resolve dependencies' do
      subject.add_dependency :a
      subject.add_dependency :b
      subject.add_dependency :c
      subject.add_dependency :d
      subject.add_dependency :e
      subject.add_dependency :a, :b
      subject.add_dependency :a, :d
      

      resolved = []
      subject.resolve :a, resolved
      p resolved
    end
  end
end