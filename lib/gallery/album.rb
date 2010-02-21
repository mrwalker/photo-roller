module Gallery
  class Album
    attr_accessor :remote, :params

    def initialize(remote, params)
      @remote, @params = remote, params
    end

    def properties(params = {})
      @remote.album_properties(name, params)
    end

    def images(params = {})
      response = @remote.fetch_album_images(name, params)
      image_params = response.keys.inject([]) do |image_params, key|
        next image_params unless key =~ /image\.(.*)\.(\d+)/
        _, param, index = key.match(/image\.(.*)\.(\d+)/).to_a
        index = index.to_i
        image_params[index] ||= {}
        image_params[index][param] = response[key]
        image_params
      end.compact # Keys are 1-based; remove first element
      image_params.map do |params|
        image = Image.new(@remote, params)
        yield image if block_given?
        image
      end
    end
    
    def name
      @params['name']
    end
    
    def title
      @params['title']
    end
    
    def parent
      @params['parent']
    end
    
    def to_s
      "Album #{name}: #{title}"
    end
  end
end
