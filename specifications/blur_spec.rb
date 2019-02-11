require_relative './spec_helper'

describe Blur do
  describe '.Script' do
    before(:each) { Blur::reset_scripts! }

    it 'should init a class derived from a superscript' do
      expect(Blur::SuperScript).to receive(:inherited)

      Blur::Script(:test) {}
    end

    it 'should add the script to the list of scripts' do
      expect(Blur.scripts).to be_empty
      Blur::Script(:test) {}
      expect(Blur.scripts).to_not be_empty
    end
  end

  describe '.scripts' do
    it 'should return a list of script classes' do
      expect(Blur.scripts).to be_kind_of Hash
    end
  end

  describe '.reset_scripts!' do
    let(:test_script) { double(:test_script).as_null_object }
    let(:scripts) { { test: test_script } }

    before :each do
      allow(Blur).to receive(:scripts).and_return scripts
    end

    it 'should clear all scripts' do
      expect(Blur.scripts).to_not be_empty
      Blur.reset_scripts!
      expect(Blur.scripts).to be_empty
    end

    it 'should call .deinit on all script classes' do
      expect(test_script).to receive :deinit

      Blur.reset_scripts!
    end
  end

  describe '.connect' do
    let(:client) { double(:client).as_null_object }
    let :test_options do
      {
        config_path: File.join(__dir__, '../', 'config.yml'),
        environment: 'testing'
      }
    end

    before do
      allow(Blur::Client).to receive(:new).and_return(client)
    end

    it 'should create a client' do
      block = proc {}

      Blur.connect(test_options, &block)
    end

    it 'should automatically connect' do
      block = {}
      expect(client).to receive(:connect)
      Blur.connect(test_options, &block)
    end
  end
end
