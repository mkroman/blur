# frozen_string_literal: true

require_relative '../spec_helper'

describe Blur::URLHandling do
  describe 'included' do
    subject { Class.new }

    before :each do
      allow(subject).to receive(:register!)
      subject.include Blur::URLHandling
    end

    it 'should create a url registry' do
      expect(subject.url_registry).to be_kind_of Blur::URLHandling::URLRegistry
    end

    it 'should register a message handler' do
      subject { Class.new }
      expect(subject).to receive(:register!).with(message: anything)
      subject.include Blur::URLHandling
    end
  end

  describe '.extract_urls' do
    subject { Blur::URLHandling }

    context 'with multiple urls' do
      let(:message) { 'hello world https://google.com this is https://example.com an example' }

      it 'should extract and return urls' do
        result = subject.extract_urls(message)
        expect(result).to be_kind_of Array

        result = result.map(&:to_s)
        expect(result).to eq ['https://google.com/', 'https://example.com/']
      end
    end

    context 'with special characters in urls' do
      let(:message) { 'I will be going with https://færøbåd.fo' }

      it 'should return normalized urls' do
        result = subject.extract_urls(message)
        expect(result).to be_kind_of Array

        result = result.map(&:to_s)
        expect(result).to eq ['https://xn--frbd-soad1k.fo/']
      end
    end
  end
end
