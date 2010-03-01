module IPhoto
  class Image
    attr_accessor :id, :params

    def initialize(id, keywords, params)
      @id, @keyword_map, @params = id, keywords, params
    end

    def keywords
      keyword_keys.map{ |key| @keyword_map[key] }
    end

    def keyword_string
      keywords.join(',')
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
      # Keywords is nil when there are no keywords defined
      @params['Keywords'] || []
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
