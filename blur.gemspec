#!/usr/bin/gem build
# encoding: utf-8

require File.dirname(__FILE__) + '/library/blur/version'

Gem::Specification.new do |spec|
  spec.name     = "blur"
  spec.version  = Blur::Version
  spec.summary  = "An event-driven IRC-framework for Ruby."

  spec.homepage = "https://github.com/mkroman/blur"
  spec.license  = "MIT"
  spec.author   = "Mikkel Kroman"
  spec.email    = "mk@uplink.io"
  spec.files    = Dir["library/**/*.rb", "README.md", "LICENSE", ".yardopts"]

  spec.add_runtime_dependency 'deep_merge', '~> 1.1'
  spec.add_runtime_dependency 'eventmachine', '~> 1.2'
  spec.add_runtime_dependency 'ircparser', '~> 0.5'
  spec.add_runtime_dependency 'semverse', '~> 2.0'

  spec.bindir = 'executables'
  spec.executables << 'blur'

  spec.require_path = "library"
  spec.required_ruby_version = ">= 1.9.1"
end

# vim: set syntax=ruby:
