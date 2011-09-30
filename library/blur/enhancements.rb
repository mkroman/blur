# encoding: utf-8

# Reopens the scope of the standard Exception-class to extend it with helpful
# methods.
class Exception
  # The pattern to match against the backtrace log.
  Pattern = /^.*?:(\d+):/
  
  # Retrieve the line on which the exception was raised from when raised inside
  # a script.
  #
  # @return Fixnum the line of the script the exception was raised on.
  def line
    backtrace[0].match(Pattern)[1].to_i + 1
  end
end

# Reopens the scope of the standard String-class to extend it with helpful
# methods.
class String
  # Checks if the string contains nothing but a numeric value.
  #
  # @return true if it is a numeric value.
  def numeric?
    self =~ /^\d+$/
  end

  # Split a string up in n chunks and then iterate through them, exactly like
  # Enumerable#each_slice.
  #
  # @return [Enumerator] list of slices.
  # @yieldreturn [Array] list of elements in each slice consecutively.
  def each_slice size = 8
    self.chars.each_slice(size).each{|slice| yield slice.join }
  end

  alias_method :starts_with?, :start_with?
  alias_method :each_block, :each_slice
end
