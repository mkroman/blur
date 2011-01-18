# encoding: utf-8

module Blur
  class Script < Module
    module MessageParsing
      MessageTrigger = "."
      
      def message user, channel, line
        return unless line.start_with? MessageTrigger
        
        command, args = line.split $;, 2
        name = :"command_#{serialize command}"
        
        if respond_to? name
          __send__ name, user, channel, args
        end
      end
      
    protected
    
      def serialize name
        name.gsub /\W/, ''
      end
    end
  end
end