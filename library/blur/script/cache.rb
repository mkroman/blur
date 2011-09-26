# encoding: utf-8

module Blur
  class Script < Module
    # The +Cache+ class enables data storing inside Blur and it scripts.
    #
    # What it does is simply store a hash, and act like it is that hash.
    #
    # When the client closes, it sends a message to all available scripts
    # and then those scripts tells the cache to save, in order to remember
    # that data and reload it at the next run.
    #
    # Cache can then save the contents of the hash to a yaml file that persists
    # in the ./cache/ directory.
    #
    # That same file is then loaded once needed again.
    class Cache
      # Get the path to the cache directory (./cache/)
      def self.path
        %{#{File.dirname File.expand_path $0}/cache}
      end
      
      # Check if there exists a cache file for the script with name +name+.
      def self.exists? name
        File.exists? "#{path}/#{name}.yml"
      end
      
      # Get a cache value by key.
      def [] key; @hash[key] end

      # Set a cache value by key.
      def []= key, value; @hash[key] = value end
      
      # Instantiate a cache with a script reference.
      def initialize script
        @hash   = {}
        @script = script
      end
      
      # Save all internal data to a yaml file in the cache directory.
      def save
        directory = File.dirname path
        
        unless File.directory? directory
          Dir.mkdir directory
        end
        
        File.open path, ?w do |file|
          YAML.dump @hash, file
        end
      end
      
      # Load a yaml file as internal data from the cache directory.
      #
      # @return [Hash] the loaded data.
      def load
        if yaml = YAML.load_file(path)
          @hash = yaml
        end
      rescue
        File.unlink path
      end
      
      # Let Hash#to_s do the job.
      def to_s; @hash end
      
    private
    
      # The current caches file path.
      #
      # @return [String] the file path.
      def path
        %{#{Cache.path}/#{@script.__name}.yml}
      end
    end
  end
end
