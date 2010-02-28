module IPhoto
  class Image
    attr_accessor :id, :params

    def initialize(id, params)
      @id, @params = id, params
    end

    def id
      @id
    end

    def guid
      @params['GUID']
    end

    def path
      @params['ImagePath']
    end

    def roll
      @params['Roll']
    end

    def caption
      @params['Caption']
    end

    def comment
      @params['Comment']
    end

    def keyword_keys
      @params['Keywords']
    end

    def media_type
      @params['MediaType']
    end

    def image_type
      @params['ImageType']
    end

    def rating
      @params['Rating']
    end

    def unused_params
      ['Faces', 'MetaModDateAsTimerInterval', 'DateAsTimerInterval', 'ThumbPath', 'AspectRatio', 'ModDateAsTimerInterval']
    end
  end
end
