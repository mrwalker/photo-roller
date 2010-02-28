module IPhoto
  class Roll
    attr_accessor :params

    def initialize(images, params)
      @image_map, @params = images, params
    end

    def images
      image_keys.map{ |key| @image_map[key] }
    end

    def id
      @params['RollID']
    end

    def name
      @params['RollName']
    end

    def size
      @params['PhotoCount']
    end

    def date
      @params['RollDateAsTimerInterval']
    end

    def image_keys
      @params['KeyList']
    end

    def key_photo_key
      @params['KeyPhotoKey']
    end
  end
end
