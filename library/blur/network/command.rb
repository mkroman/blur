# encoding: utf-8

module Blur
  class Network
    class Command
      attr_accessor :name, :params, :prefix

      Pattern = /^(?:[:@]([^\s]+) )?([^\s]+)(?: ((?:[^:\s][^\s]* ?)*))?(?: ?:(.*))?$/
      
      def self.parse data
        match = data.strip.match Pattern
        prefix, name, args, extra = match.captures
        params = extra ? args.split << extra : args.split

        new(name, params).tap do |this|
          this.prefix = prefix
        end
      end

      def initialize name, params = []
        @name, @params = name, params
      end

      def [] index; @params[index] end

      def sender
        return @sender if @sender

        if prefix =~ /^(\S+)!(\S+)@(\S+)$/
          @sender = OpenStruct.new nickname: $1, username: $2, hostname: $3
        else
          @sender = prefix
        end
      end 

      def to_s
        String.new.tap do |line|
          line << "#{prefix} " if prefix
          line << name.to_s

          params.each_with_index do |param, index|
            line << ' '
            line << ?: if index == params.length - 1 and param =~ /[ :]/
            line << param.to_s
          end
        end
      end
    end
  end
end
