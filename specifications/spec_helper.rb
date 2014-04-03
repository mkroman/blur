# encoding: utf-8

$:.unshift File.dirname(__FILE__) + '/../library'
require 'blur'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
