# frozen_string_literal: true

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
    it 'should pass the message to the client'
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
