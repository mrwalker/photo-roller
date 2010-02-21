STDOUT.sync = true
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'pp'
require 'yaml'
require 'gallery_remote'

account = YAML.load_file('account.yml')
GalleryRemote.new(account[:url]) do
  login account[:username], account[:password]
  puts status

  #albums do |album|
  #  puts "#{album}: #{status}"
  #  puts album.params.inspect
  #  album.images do |image|
  #    puts "#{image}: #{status}"
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
