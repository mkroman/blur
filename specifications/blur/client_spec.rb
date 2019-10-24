# frozen_string_literal: true

require 'tempfile'
require_relative '../spec_helper'

describe Blur::Client do
  # Since #emit uses EM.defer to synchronize the threads, we'll have to stub it
  # out to avoid an error
  before(:each) do
    allow(EM).to receive(:defer).and_yield
  end

  let :test_client_options do
    {
      config_path: File.join(__dir__, '../../', 'config.yml'),
      environment: 'testing'
    }
  end

  subject { described_class.new test_client_options }

  describe '.new' do
    context 'when no config file is specified' do
      let(:test_client_options) do
        { environment: 'testing' }
      end

      it 'should raise an error' do
        expect { subject }.to raise_error Blur::ConfigError
      end
    end

    it 'should load the specified config' do
      expect(subject.config).to_not be_empty
      expect(subject.config).to_not eq Blur::Client::DEFAULT_CONFIG
    end

    it 'should initialize networks' do
      expect(subject.networks).to_not be_empty
      expect(subject.networks).to all be_kind_of Blur::Network
    end

    it 'should trap the interrupt signal' do
      interrupt_signal = Signal.list['INT']

      expect_any_instance_of(Blur::Client).to \
        receive(:trap).with interrupt_signal

      subject
    end
  end

  describe '#connect' do
    # Stub out eventmachine to avoid runtime errors
    before :each do
      allow(EventMachine).to receive(:run).and_yield
      allow(EventMachine).to receive :error_handler
      allow_any_instance_of(Blur::Network).to receive :connect
    end

    it 'should load scripts' do
      expect(subject).to receive :load_scripts!

      subject.connect
    end

    it 'should start eventmachine' do
      expect(EM).to receive(:run)
      subject.connect
    end

    it 'should connect to each network' do
      subject.networks.each do |network|
        expect(network).to receive :connect
      end

      subject.connect
    end
  end

  describe '#got_message' do
    let(:network) { double :network }
    let(:message) { IRCParser::Message.parse 'PRIVMSG #channel message' }

    context 'when the command is valid' do
      it "should call the handler method" do
        expect(subject).to receive(:handle_privmsg).with(network, message)
        subject.got_message network, message
      end
    end

    context 'when verbose logging is enabled' do
      let(:message) { IRCParser::Message.parse 'MILK abc' }

      it 'should log the raw message' do
        subject.verbose = true

        expect do
          subject.got_message network, message
        end.to output(/MILK\s+"abc"/).to_stdout
      end
    end
  end

  describe '#network_connection_closed' do
    let(:network) { double :network }

    it 'should emit :connection_close event' do
      expect(subject).to receive(:emit).with(:connection_close, network)
      subject.network_connection_closed network
    end
  end

  describe '#quit' do
    before :each do
      allow(EventMachine).to receive :stop
      allow_any_instance_of(Blur::Network).to receive :quit
      allow_any_instance_of(Blur::Network).to receive :transmit
      allow_any_instance_of(Blur::Network).to receive :disconnect
    end

    it 'should send QUIT command' do
      subject.networks.each do |network|
        expect(network).to receive(:transmit).with(/QUIT/, any_args)
      end

      subject.quit
    end

    it 'should disconnect each network' do
      subject.networks.each do |network|
        expect(network).to receive(:disconnect)
      end

      subject.quit
    end

    it 'should stop eventmachine' do
      expect(EventMachine).to receive(:stop)

      subject.quit
    end
  end

  describe '#reload!' do
    before :each do
      allow(EventMachine).to receive(:schedule).and_yield
    end

    it 'should unload previously loaded scripts' do
      expect(subject).to receive :unload_scripts!
      subject.reload!
    end

    it 'should reload the config' do
      expect(subject).to receive :load_config!
      subject.reload!
    end

    it 'should load new scripts' do
      expect(subject).to receive :load_scripts!
      subject.reload!
    end
  end

  describe '#load_scripts!' do
    let(:scripts_dir) { File.join __dir__, '../fixtures/alphabetic_scripts' }

    before :each do
      subject.config['blur']['scripts_dir'] = scripts_dir
    end

    it 'should load scripts by filename alphabetically' do
      files = %w[00_first.rb 01_second.rb third.rb]

      files.each do |file|
        path = File.expand_path File.join scripts_dir, file
        expect(subject).to receive(:load_script_file).with(path).ordered
      end

      subject.load_scripts!
    end

    it 'should emit :scripts_loaded event' do
      expect(subject).to receive(:emit).with :scripts_loaded
      subject.load_scripts!
    end
  end

  describe '#unload_scripts!' do
    let(:scripts_dir) { File.join __dir__, '../fixtures/alphabetic_scripts' }

    before :each do
      subject.config['blur']['scripts_dir'] = scripts_dir
      subject.load_scripts!
    end

    it 'should send :unloaded to all scripts' do
      subject.scripts.each do |_, script_instance|
        expect(script_instance).to receive :unloaded
      end

      subject.unload_scripts!
    end

    it 'should reset globally loaded scripts' do
      expect(Blur).to receive :reset_scripts!

      subject.unload_scripts!
    end
  end

  describe '#load_script_file' do
    context 'when the script has a syntax error' do
      it 'should print an error' do
        temp_file = Tempfile.new ['test', '.rb']
        temp_file.write 'hello(]'
        temp_file.close

        expect { subject.load_script_file temp_file.path }.to \
          output(/The script.+failed to load/).to_stderr

        temp_file.delete
      end
    end
  end

  describe '#load_config!' do
    context 'when @config_path file exists' do
      it 'should emit :config_loaded' do
        expect(subject).to receive(:emit).with :config_load

        subject.send :load_config!
      end
    end

    context 'when @config_path file does not exist' do
      before :each do
        subject.config_path = 'doesnt-exist-anywhere.yml'
      end

      it 'should raise an error' do
        expect { subject.send :load_config! }.to raise_error Errno::ENOENT
      end
    end
  end
end
