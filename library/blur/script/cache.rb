# encoding: utf-8

module Blur
  class Script < Module
    class Cache
      
      def self.path
        %{#{File.dirname File.expand_path $0}/cache}
      end
      
      def self.exists? name
        File.exists? "#{path}/#{name}.yml"
      end
      
      def [] key; @hash[key] end
      def []= key, value; @hash[key] = value end
      
      def initialize script
        @hash   = {}
        @script = script
      end
      
      def save
        directory = File.dirname path
        
        unless File.directory? directory
          Dir.mkdir directory
        end
        
        File.open path, ?w do |file|
          YAML.dump @hash, file
        end
      end
      
      def load
        if yaml = YAML.load_file(path)
          @hash = yaml
        end
      rescue
        File.unlink path
      end
      
      def to_s; @hash end
      
    private
    
      def path
        %{#{Cache.path}/#{@script.name}.yml}
      end
    end
  end
end
