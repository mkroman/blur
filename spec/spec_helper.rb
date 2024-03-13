# frozen_string_literal: true

require_relative '../lib/blur'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
