# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Blur::SuperScript do
  describe '.create' do
    it 'should return a descendant of SuperScript' do
      script = Blur::SuperScript.create() {}
      expect(script.ancestors).to include Blur::SuperScript
    end

    it 'should raise an error when no block was given' do
      expect { Blur::SuperScript.create }.to raise_error ArgumentError
    end
  end

  context 'without attributes or arguments' do
    subject { Blur::SuperScript.create() {} }

    it 'should have a semver version of 0.0.0' do
      expect(subject.version).to be_kind_of Semverse::Version
      expect(subject.version).to eq Semverse::Version.new('0.0.0')
    end

    it 'should not have name' do
      expect(subject.name).to be_nil
    end

    it 'should not have an author' do
      expect(subject.author).to be_nil
    end
  end
end