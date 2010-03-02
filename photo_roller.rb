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

  def self.reject_images(iphoto_images, msg, &block)
    original_size = iphoto_images.size
    iphoto_images.reject!(&block)
    puts "#{original_size - iphoto_images.size} of #{original_size} photos #{msg}" if iphoto_images.size < original_size
  end

  def upload(account)
    album_data = IPhoto::AlbumData.new(account[:album_data])
    puts "Loaded iPhoto album data (#{album_data.rolls.size} rolls, #{album_data.images.size} images)"

    Gallery::Gallery.new(account[:url]) do
      login(account[:username], account[:password])
      album_cache = albums

      parent_album = album_cache.find{ |a| a.title == account[:parent_album] }
      raise "Could not find parent album '#{account[:parent_album]}; create it or modify account settings'" unless parent_album

      # TODO: remove
      count, limit = 1, 50
      File.open(account[:rejects_file], 'w') do |rejects|
        album_data.rolls.each do |roll|
          iphoto_images = roll.images
          # TODO: remove
          next if iphoto_images.size > 10
          break if count > limit
          count += 1

          puts "Roll: #{roll.name}"

          # Exclusions
          PhotoRoller.reject_images(iphoto_images, 'excluded by media type'){ |iphoto_image| account[:excluded_media_types].include?(iphoto_image.media_type) }
          PhotoRoller.reject_images(iphoto_images, 'excluded by image type'){ |iphoto_image| account[:excluded_image_types].include?(iphoto_image.image_type) }
          PhotoRoller.reject_images(iphoto_images, 'excluded by keyword'){ |iphoto_image| !(account[:excluded_keywords] & iphoto_image.keywords).empty? }

          # Don't create album if we've filtered all images
          next if iphoto_images.empty? && !roll.images.empty?

          remote_album = album_cache.find{ |a| a.title == roll.name }
          if remote_album
            # Only upload photos that don't already exist
            puts "Album exists: #{roll.name}"
            remote_photos = remote_album.images.map(&:caption)

            PhotoRoller.reject_images(iphoto_images, 'already exist in album'){ |iphoto_image| remote_photos.include?(iphoto_image.caption) }
          else
            puts "Album missing: #{roll.name}"
            parent_album.add_album(roll.name)

            # TODO: get actual name, update albums, etc.
            album_cache = albums
            remote_album = album_cache.find{ |a| a.title == roll.name }
          end

          # Don't bother uploading 0 images
          next if iphoto_images.empty?

          puts "Uploading #{iphoto_images.size} photos"
          iphoto_images.each do |iphoto_image|
            unless Gallery::Remote.supported_type?(File.extname(iphoto_image.path).downcase)
              rejects << [iphoto_image.path, '-', "MIME type for extension #{File.extname(iphoto_image.path).downcase} unknown", 'Unsupported file type'].join("\t")
              rejects << "\n"
              next
            end
            remote_album.add_item(iphoto_image.path, PhotoRoller.iphoto_image_to_params(iphoto_image))
            unless remote.status == Gallery::Remote::GR_STAT_SUCCESS
              # Failed to upload photo -- make this check more specific
              rejects << [iphoto_image.path, remote.status, remote.status_text, Gallery::Remote::STATUS_DESCRIPTIONS[remote.status]].join("\t")
              rejects << "\n"
            end
          end

          # TODO: update albums?
        end
      end
    end
  end
end
