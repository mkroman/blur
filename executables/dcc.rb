#!/usr/bin/env ruby
# encoding: utf-8

$:.unshift File.dirname(__FILE__) + '/../library'
require 'pulse'

Pulse::DCC.new('/home/mk/lol.png').listen
