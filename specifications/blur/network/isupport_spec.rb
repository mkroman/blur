require_relative '../../spec_helper'

describe Blur::Network::ISupport do
  let(:network) { double :network }

  subject do
    Blur::Network::ISupport.new network
  end

  describe ".new" do
    it "should have a network reference" do
      expect(subject.network).to eq network
    end
  end

  describe "#parse_parameter" do
    context "when the parameter is just a key" do
      it "should not return a value" do
        result = subject.send :parse_parameter, "SPAM"

        expect(result).to eq ["SPAM", nil]
      end
    end

    context "when the parameter is a key with no real value" do
      it "should not return a value" do
        result = subject.send :parse_parameter, "SPAM="

        expect(result).to eq ["SPAM", nil]
      end
    end

    context "when the parameter has a key and a value" do
      it "should return the key and the value" do
        result = subject.send :parse_parameter, "SPAM=yes"

        expect(result).to eq ["SPAM", "yes"]
      end
    end
  end

  describe "#synchronize!" do
    it "should extract the parameters as key-value pair" do
      expect(subject).to receive(:parse_parameter).at_least(3).times

      subject.synchronize! "CHANLIMIT=#:2,&:6", "SPAM", "PREFIX=(qaohvV)~&@%+-"
    end

    context "when CHANLIMIT is passed" do
      it "should parse" do

      end
    end
  end
end
