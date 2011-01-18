# encoding: utf-8

class Exception
  Pattern = /^.*?:(\d+):/
  
  def line
    backtrace[0].match(Pattern)[1].to_i + 1
  end
end

class String
  alias_method :starts_with?, :start_with?
end
