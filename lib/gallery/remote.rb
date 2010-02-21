require 'cgi'
require 'net/http'
require 'cookie_jar'

module Gallery
  class Remote
    attr_accessor :last_response

    GR_STAT_SUCCESS = 0
    PROTO_MAJ_VER_INVAL = 101
    PROTO_MIN_VER_INVAL = 102
    PROTO_VER_FMT_INVAL = 103
    PROTO_VER_MISSING = 104
    PASSWD_WRONG = 201
    LOGIN_MISSING = 202
    UNKNOWN_CMD = 301
    NO_ADD_PERMISSION = 401
    NO_FILENAME = 402
    UPLOAD_PHOTO_FAIL = 403
    NO_WRITE_PERMISSION = 404
    NO_VIEW_PERMISSIO = 405
    NO_CREATE_ALBUM_PERMISSION = 501
    CREATE_ALBUM_FAILED = 502
    MOVE_ALBUM_FAILED = 503
    ROTATE_IMAGE_FAILED = 504
    STATUS_DESCRIPTIONS = { 
      GR_STAT_SUCCESS => 'The command the client sent in the request completed successfully. The data (if any) in the response should be considered valid.',
      PROTO_MAJ_VER_INVAL => 'The protocol major version the client is using is not supported.',
      PROTO_MIN_VER_INVAL => 'The protocol minor version the client is using is not supported.',
      PROTO_VER_FMT_INVAL => 'The format of the protocol version string the client sent in the request is invalid.',
      PROTO_VER_MISSING => 'The request did not contain the required protocol_version key.',
      PASSWD_WRONG => 'The password and/or username the client send in the request is invalid.',
      LOGIN_MISSING => 'The client used the login command in the request but failed to include either the username or password (or both) in the request.',
      UNKNOWN_CMD => 'The value of the cmd key is not valid.',
      NO_ADD_PERMISSION => 'The user does not have permission to add an item to the gallery.',
      NO_FILENAME => 'No filename was specified.',
      UPLOAD_PHOTO_FAIL => 'The file was received, but could not be processed or added to the album.',
      NO_WRITE_PERMISSION => 'No write permission to destination album.',
      NO_VIEW_PERMISSIO => 'No view permission for this image.',
      NO_CREATE_ALBUM_PERMISSION => 'A new album could not be created because the user does not have permission to do so.',
      CREATE_ALBUM_FAILED => 'A new album could not be created, for a different reason (name conflict).',
      MOVE_ALBUM_FAILED => 'The album could not be moved.',
      ROTATE_IMAGE_FAILED => 'The image could not be rotated' 
    }          

    @@supported_types = { '.jpg' => 'image/jpeg' }

    def initialize(url)
      @uri = URI.parse(url)
      @base_params = {
        'g2_controller' => 'remote:GalleryRemote',
        'g2_form[protocol_version]'=>'2.9'
      }
      @cookie_jar = CookieJar.new    
      @boundary = '7d21f123d00c4'
    end

    def login(uname, password, params = {})
      params = { :cmd => 'login', :uname => uname, :password => password }.merge(params)
      send_request(params)
    end

    def fetch_albums_prune(params = {})
      params = { :cmd => 'fetch-albums-prune', :no_perms => 'y' }.merge(params)
      send_request(params)
    end

    #def add_item(file_name, set_albumName, params = {})
    #  params = { :cmd => 'add-item', :set_albumName => set_albumName }.merge(params)
    #  send_request(params, file_name)
    #end

    def album_properties(set_albumName, params = {})
      params = { :cmd => 'album-properties', :set_albumName => set_albumName }.merge(params)
      send_request(params)
    end

    def fetch_album_images(set_albumName, params = {})
      params = { :cmd => 'fetch-album-images', :set_albumName => set_albumName }.merge(params)
      send_request(params)
    end

    def image_properties(id, params = {})
      params = { :cmd => 'image-properties', :id => id }.merge(params)
      send_request(params)
    end
    
    def status
      "#{@status} - (#{@status_text})"
    end
    
    private
    
    def build_multipart_query(params, file_name)
      params["g2_form[userfile_name]"] = file_name  
      result = params.map{ |k, v| "Content-Disposition: form-data; name=\"#{k}\"\r\n\r\n#{v}\r\n" } #CGI::escape(
      content = open( file_name ) { |f| f.read }
      result << "Content-Disposition: form-data; name=\"g2_form[userfile]\"; filename=\"#{file_name}\"\r\n" +
        "Content-Transfer-Encoding: binary\r\n" +
        "Content-Type: #{@@supported_types[File.extname(file_name)]}\r\n\r\n" + 
        content + "\r\n"
      result.collect { |p| "--#{@boundary}\r\n#{p}" }.join("") + "--#{@boundary}--"
    end
    
    def build_query(params)
      params.map{ |k, v| "#{k}=#{v}" }.join("&") 
    end
    
    def send_request(params, file_name=nil)
      post_parameters = prep_params(params)
      headers = {}    
      headers["Cookie"] = @cookie_jar.cookies if @cookie_jar.cookies
      if(file_name && File.file?(file_name))
        query = build_multipart_query(post_parameters, file_name)
        headers["Content-type"] = "multipart/form-data, boundary=#{@boundary} " if @boundary
      else
        query = build_query(post_parameters)
      end
      res = post(query, headers)
      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        handle_response(res)
      else
        res.error!
      end
    end

    def post(query, headers = {})
      Net::HTTP.start(@uri.host, @uri.port) { |h|
        h.post( @uri.path, query, headers )
      }
    end
    
    def prep_params(params)
      result = {}
      result = result.merge(@base_params)
      params.each_pair do |name, value|
        result["g2_form[#{name}]"] = value
      end
      params["g2_authToken"] = @auth_token if @auth_token
      result
    end
    
    def handle_response(res)
      @cookie_jar.add(res.header.get_fields("set-cookie"))  
      @last_response = {}
      res.body.each do |line|
        name, *values = line.strip.split(/\s*=\s*/)
        @last_response[name.strip] = values.join "="
      end
      @auth_token = @last_response['auth_token']
      @status = @last_response['status']
      @status_text = @last_response['status_text']
      @last_response
    end
  end
end
