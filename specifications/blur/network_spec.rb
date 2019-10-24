require_relative '../spec_helper'

RSpec.describe Blur::Network do
  describe '.new' do
    context 'when no nickname is supplied' do
      it 'should raise an error'
    end

    context 'when no hostname is supplied' do
      it 'should raise an error'
    end

    it 'should use nickname as username if no username is supplied'
    it 'should use username as realname if no realname is supplied'
  end

  describe '#say' do
    it 'should send a PRIVMSG'
  end

  describe '#got_message' do
    subject do
      client = double(:client, verbose: true)

      Blur::Network.new({ 'nickname' => 'test', 'hostname' => 'irc.test.org' }, client)
    end

    let(:network) { double :network }
    let(:message) { IRCParser::Message.parse 'PRIVMSG #channel message' }

    context 'when the command is valid' do
      it "should call the handler method" do
        expect(subject).to receive(:handle_privmsg).with(message)
        subject.got_message message
      end
    end

    context 'when verbose logging is enabled' do
      let(:message) { IRCParser::Message.parse 'MILK abc' }

      it 'should log the raw message' do
        expect do
          subject.got_message message
        end.to output(/MILK\s+"abc"/).to_stdout
      end
    end
  end

  describe '#channels_by_name' do
    it 'should return channel with a matching name'
    it 'should return nil if no channel matches'
  end

  describe '#channels_with_user' do
    context 'when the requested user nick is in several shared channels' do
      it 'should return those channels'
    end

    context 'when the requested user nick is not found' do
      it 'should return an empty list'
    end
  end

  describe '#transmit' do
    it 'should generate and send an IRC command'
  end

  describe '#join' do
    it 'should send a JOIN command'
  end
end
