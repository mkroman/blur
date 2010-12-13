# encoding: utf-8

module Pulse
  class Script
    class Cache
      def initialize script
        @script = script
        @containers = {}
      end

      def save
        create_directory

        File.open path, ?w do |file|
          YAML.dump @containers, file
        end

        puts "Dumping cache for script #{@script.name} to #{path} …"
      end

      def load
        if data = YAML.load_file(path)
          puts "Imported cache from #{path} …" if @containers = data
        end
      rescue
        puts "The cache is corrupted. Removing."
        File.unlink path
      end

      def containers; @containers.keys end
      def clear sure = false; @containers.clear if sure end

      def [] key; @containers[key] ||= {} end
      def []= key, value; @containers[key] = value end

    private

      def create_directory
        Dir.mkdir File.dirname path unless File.directory? File.dirname path
      end

      def path
        "#{File.dirname File.expand_path $0}/cache/#{@script.name}.yml"
      end
    end
  end
end
