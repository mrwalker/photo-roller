#! /usr/bin/env ruby

require 'photo_roller'

PhotoRoller.new.upload(YAML.load_file('account.yml'))
