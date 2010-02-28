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

  @@album_mapping = {
    #'title' => :newAlbumTitle,
    'description' => :newAlbumDesc
  }

  @@photo_mapping = {
    #'file_name' => :userfile,
    'title' => :caption,
    'description' => :'extrafield.Description'
  }

  def album_to_params(album)
    @@album_mapping.inject({}) do |remote, (album_key, remote_key)|
      remote[remote_key] = album[album_key] if album[album_key]
      remote
    end
  end

  def photo_to_params(photo)
    @@photo_mapping.inject({}) do |remote, (photo_key, remote_key)|
      remote[remote_key] = photo[photo_key] if photo[photo_key]
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

  def upload(album_data)
    album_data.each do |album, photos|
      remote_album = albums.find{ |a| a.title == album['title'] }
      if remote_album
        puts "Album exists: #{album['title']}"
        to_upload = photos.size

        # Only upload photos that don't already exist
        remote_photos = remote_album.images.map(&:caption)
        puts gallery.remote.status

        photos = photos.reject{ |p| remote_photos.include?(p['title']) }
        puts "#{to_upload - photos.size} photos already exist in album; not uploading" if photos.size < to_upload
      else
        puts "Album missing: #{album['title']}"

        parent_album.add_album(album['title'], album_to_params(album))
        puts gallery.remote.status

        # TODO: get actual name, update albums, etc.
        albums = gallery.albums
        puts gallery.remote.status

        remote_album = albums.find{ |a| a.title == album['title'] }
      end

      puts "Uploading #{photos.size} photos"
      photos.each do |photo|
        remote_album.add_item(photo['file_name'], photo_to_params(photo))
        puts gallery.remote.status
      end

      # TODO: update albums?
    end
  end
end

#PhotoRoller.new.upload(ALBUM_DATA)

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
