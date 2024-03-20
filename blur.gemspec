#!/usr/bin/gem build
# frozen_string_literal: true

require_relative 'lib/blur/version'

Gem::Specification.new do |spec|
  spec.name     = 'blur'
  spec.version  = Blur.version
  spec.summary  = 'An event-driven IRC-framework for Ruby.'

  spec.homepage = 'https://github.com/mkroman/blur'
  spec.license  = 'MIT'
  spec.author   = 'Mikkel Kroman'
  spec.email    = 'mk@maero.dk'
  spec.files    = Dir['lib/**/*.rb', 'README.md', 'LICENSE', '.yardopts']

  spec.add_runtime_dependency 'addressable', '~> 2.8'
  spec.add_runtime_dependency 'async', '~> 2.9'
  spec.add_runtime_dependency 'async-io', '~> 1.41'
  spec.add_runtime_dependency 'deep_merge', '~> 1.2'
  spec.add_runtime_dependency 'ircparser', '~> 1.0'
  spec.add_runtime_dependency 'semantic_logger', '~> 4.15'

  spec.executables << 'blur'

  spec.required_ruby_version = '>= 3.3'
end

# vim: set syntax=ruby:
