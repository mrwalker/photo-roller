$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'yaml'
require 'gallery'
require 'iphoto'

class PhotoRoller
  @@photo_mapping = {
    #'file_name' => :userfile,
    :caption => :caption,
    :comment => :'extrafield.Description'
    # GalleryRemote does not support keywords
    #:keyword_string => :'extrafield.Keywords'
  }

  def self.iphoto_image_to_params(iphoto_image)
    @@photo_mapping.inject({}) do |remote, (photo_key, remote_key)|
      remote[remote_key] = iphoto_image.send(photo_key) if iphoto_image.send(photo_key)
      remote
    end
  end

  def upload(account)
    album_data = IPhoto::AlbumData.new(account[:album_data])
    puts "Loaded iPhoto album data (#{album_data.rolls.size} rolls, #{album_data.images.size} images)"

    Gallery::Gallery.new(account[:url]) do
      login(account[:username], account[:password])
      album_cache = albums

      parent_album = album_cache.find{ |a| a.title == account[:parent_album] }
      #parent_album ||= Gallery::Album.new(remote, { 'name' => '0', 'title' => 'Gallery' })

      count, limit = 1, 50
      album_data.rolls.each do |roll|
        iphoto_images = roll.images
        next if iphoto_images.size > 10
        break if count > limit
        count += 1

        remote_album = album_cache.find{ |a| a.title == roll.name }
        if remote_album
          # Only upload photos that don't already exist
          puts "Album exists: #{roll.name}"
          remote_photos = remote_album.images.map(&:caption)

          iphoto_images = iphoto_images.reject{ |iphoto_image| remote_photos.include?(iphoto_image.caption) }
          puts "#{roll.images.size - iphoto_images.size} of #{roll.images.size} photos already exist in album" if iphoto_images.size < roll.images.size
        else
          puts "Album missing: #{roll.name}"
          parent_album.add_album(roll.name)

          # TODO: get actual name, update albums, etc.
          album_cache = albums

          remote_album = album_cache.find{ |a| a.title == roll.name }
        end

        puts "Uploading #{iphoto_images.size} photos"
        iphoto_images.each do |iphoto_image|
          remote_album.add_item(iphoto_image.path, PhotoRoller.iphoto_image_to_params(iphoto_image))
          unless remote.status == Gallery::Remote::GR_STAT_SUCCESS
            # Failed to upload photo -- make this check more specific
            puts iphoto_image.path
          end
        end

        # TODO: update albums?
      end
    end
  end
end
