#! /usr/bin/env ruby

require 'yaml'
require 'rubygems'
require 'gallery'

def upload(account)
  Gallery::Gallery.new(account[:url]) do
    login(account[:username], account[:password])

    parent_name = 'Reverse Engineering Image Escaping'
    album_cache = albums
    parent_album = album_cache.find{ |a| a.title == parent_name }

    unless parent_album
      root_album = album_cache.find{ |a| a.title == account[:parent_album] }
      raise "Could not find root album '#{account[:parent_album]}; create it or modify account settings'" unless root_album

      root_album.add_album(parent_name)
      raise "Could not create parent album '#{parent_name}'" unless remote.status == Gallery::Remote::GR_STAT_SUCCESS

      album_cache = albums
      parent_album = album_cache.find{ |a| a.title == parent_name }
    end

    image_cache = parent_album.images

    test_name = lambda do |char, caption|
      remote_image = image_cache.find{ |i| i.caption == caption }
      if remote_image
        raise "Image already exists: #{caption}"
      else
        puts "Image missing: #{caption}"
        response = parent_album.add_item('test_image.jpg', :caption => caption)
        raise "Could not add image: #{caption}" unless remote.status == Gallery::Remote::GR_STAT_SUCCESS

        image_cache = parent_album.images
        remote_image = image_cache.find{ |i| i.caption == caption }
        if remote_image
          puts "Names matched: #{caption}; '#{char}' requires no escape"
          char
        else
          puts "Did not find: #{caption} at #{response['item_name']}"
          remote_image = image_cache.find{ |i| i.name == response['item_name'] }
          puts "Found: #{remote_image.caption} by name: #{remote_image.name}; '#{char}' requires escaping"
          remote_image.caption.match(/Contains (.*) char/).to_a.last
        end
      end
    end

    chars = [':', ';', "'", '"', ',', '.', '/', '?',
      '<', '>', '[', ']', '{', '}', '\\', '|', '-', '_', '+', '=', '`', '~',
      '!', '@', '#', '$', '%', '^', '&', '*', '(', ')']
    escapes = chars.map do |char|
      test_name.call(char, "Contains #{char} char")
    end

    escape_map = Hash[*chars.zip(escapes).sort.flatten]
    File.open('image_escapes.yml', 'w+'){ |f| f << YAML.dump(escape_map) }
  end
end

upload(YAML.load_file('account.yml'))
