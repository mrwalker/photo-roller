#! /usr/bin/env ruby

require 'yaml'
require 'rubygems'
require 'gallery'

module Gallery
  class Gallery
    def test_album_name(char, name)
      remote_album = @album_cache.find{ |a| a.title == name }
      if remote_album
        raise "Album already exists: #{name}"
      else
        puts "Album missing: #{name}"
        response = @test_album.add_album(name)
        raise "Could not create album: #{name}" unless remote.status == Remote::GR_STAT_SUCCESS

        @album_cache = albums
        remote_album = @album_cache.find{ |a| a.title == name }
        if remote_album
          puts "Names matched: #{name}; '#{char}' requires no escape"
          char
        else
          puts "Did not find: #{name} at #{response['album_name']}"
          remote_album = @album_cache.find{ |a| a.name == response['album_name'] }
          puts "Found: #{remote_album.title} by name: #{remote_album.name}; '#{char}' requires escaping"
          remote_album.title.match(/Contains (.*) char/).to_a.last
        end
      end
    end

    def test_image_name(char, caption)
      remote_image = @image_cache.find{ |i| i.caption == caption }
      if remote_image
        raise "Image already exists: #{caption}"
      else
        puts "Image missing: #{caption}"
        response = @test_album.add_item('test_image.jpg', :caption => caption)
        raise "Could not add image: #{caption}" unless remote.status == Remote::GR_STAT_SUCCESS

        @image_cache = @test_album.images
        remote_image = @image_cache.find{ |i| i.caption == caption }
        if remote_image
          puts "Names matched: #{caption}; '#{char}' requires no escape"
          char
        else
          puts "Did not find: #{caption} at #{response['item_name']}"
          remote_image = @image_cache.find{ |i| i.name == response['item_name'] }
          puts "Found: #{remote_image.caption} by name: #{remote_image.name}; '#{char}' requires escaping"
          remote_image.caption.match(/Contains (.*) char/).to_a.last
        end
      end
    end
  end
end

class Escaper
  def escape(account)
    Gallery::Gallery.new(account[:url]) do
      login(account[:username], account[:password])

      test_album_title = 'Reverse Engineering Escaping'
      @album_cache = albums
      @test_album = @album_cache.find{ |a| a.title == test_album_title }

      unless @test_album
        parent_album = @album_cache.find{ |a| a.title == account[:parent_album] }
        raise "Could not find parent album '#{account[:parent_album]}; create it or modify account settings'" unless parent_album

        parent_album.add_album(test_album_title)
        raise "Could not create test album '#{test_album_title}'" unless remote.status == Gallery::Remote::GR_STAT_SUCCESS

        @album_cache = albums
        @test_album = @album_cache.find{ |a| a.title == test_album_title }
      end

      @image_cache = @test_album.images

      chars = [':', ';', "'", '"', ',', '.', '/', '?',
        '<', '>', '[', ']', '{', '}', '\\', '|', '-', '_', '+', '=', '`', '~',
        '!', '@', '#', '$', '%', '^', '&', '*', '(', ')']

      escapes = chars.map do |char|
        test_album_name(char, "Contains #{char} char")
      end
      escape_map = Hash[*chars.zip(escapes).sort.flatten]
      File.open('album_escapes.yml', 'w+'){ |f| f << YAML.dump(escape_map) }

      escapes = chars.map do |char|
        test_image_name(char, "Contains #{char} char")
      end
      escape_map = Hash[*chars.zip(escapes).sort.flatten]
      File.open('image_escapes.yml', 'w+'){ |f| f << YAML.dump(escape_map) }
    end
  end
end

Escaper.new.escape(YAML.load_file('account.yml'))
