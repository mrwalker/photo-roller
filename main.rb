#! /usr/bin/env ruby

STDOUT.sync = true
$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'pp'
require 'yaml'
require 'gallery'
require 'iphoto'

ALBUM_DATA = [
  [
    { 'title' => 'Artwork', 'description' => 'Drawings, etc.' },
    [{'file_name' => 'whale.jpg', 'title' => 'Hurt Whale', 'description' => 'An injured whale'}]
  ],
  [
    { 'title' => 'Whale Stuff', 'description' => 'Pictures of whales' },
    [{'file_name' => 'whale.jpg', 'title' => 'Whale', 'description' => 'This is a whale'}]
  ]
]

class PhotoRoller
  attr_accessor :account, :album_data, :gallery, :albums, :parent_album

  @@photo_mapping = {
    #'file_name' => :userfile,
    :caption => :caption,
    :comment => :'extrafield.Description'
    # TODO: keywords => 'extrafield.Keywords' ?
  }

  def iphoto_image_to_params(iphoto_image)
    @@photo_mapping.inject({}) do |remote, (photo_key, remote_key)|
      remote[remote_key] = iphoto_image.send(photo_key) if iphoto_image.send(photo_key)
      remote
    end
  end

  def initialize
    @account = YAML.load_file('account.yml')
    @album_data = IPhoto::AlbumData.new(account[:album_data])

    @gallery = Gallery::Gallery.new(account[:url])
    @gallery.login(account[:username], account[:password])
    puts @gallery.remote.status

    @albums = @gallery.albums
    puts @gallery.remote.status

    @parent_album = @albums.find{ |a| a.title == @account[:parent_album] }
    #@parent_album ||= Gallery::Album.new(@gallery.remote, { 'name' => '0', 'title' => 'Gallery' })
  end

  def upload
    count, limit = 1, 6
    @album_data.rolls.each do |roll|
      iphoto_images = roll.images
      next if iphoto_images.size > 10
      break if count > limit
      count += 1

      remote_album = albums.find{ |a| a.title == roll.name }
      if remote_album
        puts "Album exists: #{roll.name}"

        # Only upload photos that don't already exist
        remote_photos = remote_album.images.map(&:caption)
        puts gallery.remote.status

        iphoto_images = iphoto_images.reject{ |iphoto_image| remote_photos.include?(iphoto_image.caption) }
        puts "#{roll.images.size - iphoto_images.size} of #{roll.images.size} photos already exist in album" if iphoto_images.size < roll.images.size
      else
        puts "Album missing: #{roll.name}"

        parent_album.add_album(roll.name)
        puts gallery.remote.status

        # TODO: get actual name, update albums, etc.
        albums = gallery.albums
        puts gallery.remote.status

        remote_album = albums.find{ |a| a.title == roll.name }
      end

      puts "Uploading #{iphoto_images.size} photos"
      iphoto_images.each do |iphoto_image|
        remote_album.add_item(iphoto_image.path, iphoto_image_to_params(iphoto_image))
        puts gallery.remote.status
      end

      # TODO: update albums?
    end
  end
end

PhotoRoller.new.upload

#Gallery::Gallery.new(account[:url]) do
#  login account[:username], account[:password]
#  puts remote.status
#
#  albums = albums
#  puts remote.status
#
#  parent_album = albums.find{ |a| a.title == account[:parent_album] }
#  parent_album ||= Album.new(remote, { 'name' => '0', 'title' => 'Gallery' })
#end

#Gallery::Gallery.new(account[:url]) do
#  login account[:username], account[:password]
#  puts remote.status
#
#  album = albums.find{ |a| a.title == 'Gallery' }
#  puts "#{album}: #{remote.status}"
#
#  new_album = album.add_album('Test Album')
#  puts "#{new_album.inspect}: #{remote.status}"
#  name = new_album['album_name']
#
#  new_album = albums.find{ |a| a.name == name }
#  puts "#{new_album}: #{remote.status}"
#  pp new_album.images
#
#  response = new_album.add_item('whale.jpg')
#  puts "#{response.inspect}: #{remote.status}"
#  pp new_album.images
#
#  #albums do |album|
#  #  puts "#{album}: #{remote.status}"
#  #  puts album.params.inspect
#  #  album.images do |image|
#  #    puts "#{image}: #{remote.status}"
#  #    puts image.params.inspect
#  #  end
#  #end
#
#  #names = albums.inject({}) do |names, album|
#  #  print '.'
#  #  images = album.images
#  #  print images.size
#  #  names[album.name] = images.map{ |i| i.name }
#  #  names
#  #end
#
#  #pp names
#end
