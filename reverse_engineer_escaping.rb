#! /usr/bin/env ruby

require 'yaml'
require 'rubygems'
require 'gallery'

def upload(account)
  Gallery::Gallery.new(account[:url]) do
    login(account[:username], account[:password])
    album_cache = albums

    root_album = album_cache.find{ |a| a.title == account[:parent_album] }
    raise "Could not find root album '#{account[:parent_album]}; create it or modify account settings'" unless root_album

    response = root_album.add_album('Reverse Engineering Escaping')
    raise "Could not create parent album '#{Reverse Engineering Escaping}" unless remote.status == Gallery::Remote::GR_STAT_SUCCESS

    album_cache = albums
    parent_album = album_cache.find{ |a| a.title == "Reverse Engineering Escaping" }

    test_name = lambda do |char, name|
      remote_album = album_cache.find{ |a| a.title == name }
      if remote_album
        raise "Album already exists: #{name}"
      else
        puts "Album missing: #{name}"
        response = parent_album.add_album(name)
        raise "Could not create album: #{name}" unless remote.status == Gallery::Remote::GR_STAT_SUCCESS

        album_cache = albums
        remote_album = album_cache.find{ |a| a.title == name }
        if remote_album
          puts "Names matched: #{name}; '#{char}' requires no escape"
        else
          puts "Did not find: #{name} at #{response['albun_name']}"
          remote_album = album_cache.find{ |a| a.name == response['album_name'] }
          puts "Found: #{remote_album.title} by name: #{remote_album.name}; '#{char}' requires escaping"
          remote_album.title.match(/Contains (.*) char/).to_a.last
        end
      end
    end

    chars = [':', ';', "'", '"', ',', '.', '/', '?',
      '<', '>', '[', ']', '{', '}', '\\', '|', '-', '_', '+', '=', '`', '~',
      '!', '@', '#', '$', '%', '^', '&', '*', '(', ')']
    escapes = chars.map do |char|
      test_name.call(char, "Contains #{char} char")
    end

    escape_map = Hash[*chars.zip(escapes).flatten]
    File.open('escapes.yml', 'w+'){ |f| f << YAML.dump(escape_map) }
  end
end

upload(YAML.load_file('account.yml'))
