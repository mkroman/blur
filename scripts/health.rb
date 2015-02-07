# encoding: utf-8

module ::Blur
  module Commands
    def self.included klass
    end

    def self.module_init skript
      skript.instance_variable_set :@commands, []
    end

    def command syntax, &block
      p @commands << Command.new(syntax, block)
    end

    class Command
      def initialize syntax, block
        @syntax = syntax
        @block = block
      end
    end
  end
end

Script :health do
  include Blur::Commands

  Author 'Mikkel Kroman'
  Version '0.1'
  Description 'Hello world'
  
  def initialize
  end

  client.on :message do |user, channel, line|
    if line == '.health'
      channel.say 'd'
    end
  end

  command '.abc' do |user, channel|

  end

  command '.test' do |user, channel|
    channel.say "d"
  end
end
