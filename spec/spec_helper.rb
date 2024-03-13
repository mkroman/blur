# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require 'simplecov-cobertura'
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

require_relative '../lib/blur'
require_relative '../lib/blur/cli'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
