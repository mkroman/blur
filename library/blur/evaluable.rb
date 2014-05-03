# encoding: utf-8

module Blur
  module Evaluable
    # Evaluate the contents of the input file in the context of +self+.
    def evaluate_source_file path
      instance_eval File.read(path), File.basename(path), 0

      @__evaluated = true
    rescue Exception => exception
      puts "#{exception.message ^ :bold} on line #{exception.line.to_s ^ :bold}"
    end
  end
end
