require_relative '../spec_helper'

class CallbacksStub
  include Blur::Callbacks
end

describe Blur::Callbacks do
  subject { CallbacksStub.new }

  before do
    subject.instance_variable_set(:@scripts, {})
  end

  describe "included" do
    it "should initialise @callbacks" do
      callbacks = subject.callbacks

      expect(callbacks).to be_kind_of Hash
    end
  end

  describe "#emit" do
    let(:test_1) { double :test_1 }
    let(:test_2) { double :test_2 }
    let(:test_1_2) { double :test_1_2 }
    let(:callbacks) { { test_1: [test_1, test_1_2], test_2: [test_2] } }

    before do
      allow_any_instance_of(Blur::Callbacks).to receive(:callbacks).and_return callbacks
      allow(EventMachine).to receive(:defer).and_yield
    end

    context "when there are no matching callbacks" do
      it "should not call any callbacks" do
        expect(test_1).to_not receive :call
        expect(test_2).to_not receive :call

        subject.emit :invalid_event_name, 1, 2, 3
      end
    end

    context "when there are matching callbacks" do
      it "should call each of them" do
        expect(test_1).to receive :call
        expect(test_1_2).to receive :call
        expect(test_2).to_not receive :call

        subject.emit :test_1, 1, 2
      end
    end
  end

  describe "#on" do
    it "should add an event handler" do
      subject.on(:event_name) {}

      expect(subject.callbacks).to have_key :event_name
    end

    it "should add an array for the event name" do
      subject.on(:event_name) {}

      expect(subject.callbacks[:event_name]).to be_kind_of Array
    end
  end
end
