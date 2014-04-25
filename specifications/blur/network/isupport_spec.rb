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

  describe "#parse" do
    context "when given a param that needs special treatment" do
      let(:params) { ["PREFIX=(qaohvV)~&@%+-", "SIMPLE=PARAM"] }

      it "should call the parser" do
        stub = double
        expect(stub).to receive(:call).once

        stub_const "Blur::Network::ISupport::Parsers", { "PREFIX" => stub }

        subject.parse *params
      end

      it "should successfully assign" do
        old_prefix = subject["PREFIX"]

        subject.parse *params

        expect(subject["PREFIX"]).to_not be old_prefix
      end
    end

    context "when given PREFIX" do
      let(:params) { ["PREFIX=(qaohvV)~&@%+-", "SIMPLE=PARAM"] }

      it "should parse modes and prefixes" do
        subject.parse *params

        expect(subject['PREFIX']['V']).to eq '-'
      end
    end

    context "when given CHANMODES" do
      let(:params) { ["CHANMODES=Ibeg,k,FJLfjl,ABCDGKMNOPQRSTcimnprstu", "SIMPLE=PARAM"] }

      it "should parse and split modes" do
        subject.parse *params

        expect(subject['CHANMODES']).to include ?A, ?B, ?C, ?D
      end

      it "should parse and split modes into the right groups" do
        subject.parse *params

        chanmodes = subject["CHANMODES"]

        expect(chanmodes["A"]).to include *"Ibeg".chars
        expect(chanmodes["B"]).to include "k"
        expect(chanmodes["C"]).to include *"FJLfjl".chars
        expect(chanmodes["D"]).to include *"ABCDGKMNOPQRSTcimnprstu".chars
      end
    end

    context "when given CHANLIMIT" do
      let(:params) { ["CHANLIMIT=#+:10,&:", "SIMPLE=PARAM"] }

      it "should parse and split modes into the right groups" do
        subject.parse *params

        chan_limit = subject["CHANLIMIT"]

        expect(chan_limit).to include "+" => 10
        expect(chan_limit).to include "#" => 10
      end

      it "should set an unspecified limit to infinite" do
        subject.parse *params

        chan_limit = subject["CHANLIMIT"]

        expect(chan_limit).to include "&" => Float::INFINITY
      end
    end

    context "when given a simple value-based parameter" do
      let(:params) { ["SIMPLEVAR=SIMPLEVAL"] }

      it "should successfully assign the value" do
        subject.parse *params

        expect(subject["SIMPLEVAR"]).to eq "SIMPLEVAL"
      end

    end
  end
end
