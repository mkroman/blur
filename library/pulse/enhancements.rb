# encoding: utf-8

class String
  alias_method :starts_with?, :start_with?
end

class Exception
  def line
    backtrace[0].match(/^.*?:(\d+):/)[1].to_i
  end
end
