#! /usr/bin/env ruby

STDOUT.sync = true
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'pp'
require 'yaml'
require 'gallery'

account = YAML.load_file('account.yml')
Gallery::Gallery.new(account[:url]) do
  login account[:username], account[:password]
  puts remote.status

  #albums do |album|
  #  puts "#{album}: #{remote.status}"
  #  puts album.params.inspect
  #  album.images do |image|
  #    puts "#{image}: #{remote.status}"
  #    puts image.params.inspect
  #  end
  #end

  names = albums.inject({}) do |names, album|
    print '.'
    images = album.images
    print images.size
    names[album.name] = images.map{ |i| i.name }
    names
  end

  pp names
end
