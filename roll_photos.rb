#! /usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'photo_roller'

PhotoRoller.new.upload(YAML.load_file('config/account.yml'))
