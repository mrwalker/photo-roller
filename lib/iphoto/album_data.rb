require 'rubygems'
require 'plist'

module IPhoto
  class AlbumData
    attr_accessor :images, :rolls, :keywords

    def initialize(file_name)
      album_data = Plist::parse_xml(file_name)
      @images = album_data['Master Image List'].inject({}) do |images, i|
        image = Image.new(i.first, i.last)
        images[image.id] = image
        images
      end
      @rolls = album_data['List of Rolls'].map{ |r| Roll.new(@images, r) }
      @keywords = album_data['List of Keywords']
      #pp album_data.keys.map{ |k| [k, album_data[k].kind_of?(Enumerable) ? album_data[k].size : nil] }
    end
  end
end
