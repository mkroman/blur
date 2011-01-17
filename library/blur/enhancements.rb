# encoding: utf-8

class Exception
  def line; backtrace.first.match(/^.*?:(\d+):/)[1].to_i end
end

class String
  alias_method :starts_with?, :start_with?
end
