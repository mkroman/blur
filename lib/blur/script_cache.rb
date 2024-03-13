# frozen_string_literal: true

module Blur
  class ScriptCache
    def initialize script_name, path, hash
      @script_name = script_name
      @path = path
      @hash = hash
    end

    # Gets a cache +value+ by its +key+.
    def [] key
      @hash[key]
    end

    # Sets the cache +key+ to the provided +value+.
    def []= key, value
      @hash[key] = value
    end

    # Saves the cache as a YAML file.
    def save
      directory = File.dirname @path

      Dir.mkdir directory unless File.directory? directory

      File.open @path, 'w' do |file|
        YAML.dump @hash, file
      end
    end

    # Loads the cache file for +script_name+ in +cache_dir+ if it exists.
    def self.load script_name, cache_dir
      cache_path = File.join cache_dir, "#{script_name}.yml"

      if File.exist? cache_path
        object = YAML.load_file cache_path

        ScriptCache.new script_name, cache_path, object
      else
        ScriptCache.new script_name, cache_path, {}
      end
    end
  end
end
