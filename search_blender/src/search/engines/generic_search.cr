require "../query/parser"
require "http/client"
require "logger"
require "json"


class Error < Exception
  getter code

  def initialize(@code : String, message : String )
    super(message)
  end

  def to_json
    JSON.parse("code :#{@code}; message: #{@message}")
  end
  
end

class GenericSearch 
  # include Enumerable(String)
 # FILE = File.new("./logs/search_blender_debug.log", "a")

  def initialize(@logger : Logger = Logger.new(STDOUT))
    #writer=IO::MultiWriter.new(FILE, STDOUT)
    #Logger.new(writer)
    @logger = Logger.new(STDOUT)
    @logger = searchblender_logger()
  end
  
  def build_url(q, f, options = {} of String => String)
    query = "#{q}"
    if !f.empty?
      if q.empty?
        query = f
      else
        query = "(#{q}) AND (#{f})"
      end
    end
   
    offset = options.has_key?("from") ? options["from"] : "0"
    limit  = options.has_key?("step") ? options["step"] : "10"
    sort  = options.has_key?("s") ? options["s"] : "relevance"
    url = "" ## query ?? (query,filter,sort)
    [url, offset, limit]
  end

 
  def query(q, f, options = {} of String => String)
    url, offset, limit = build_url(q, f, options)
    puts "default/generic query"


    r = {} of String => String
    r["code"] = "100"
    r["message"] = "This Must be Changed [generic query]"
    r.to_json
  end

  
  def build_record_url(id, options = {} of String => String)
    id
  end


  def record(id, options = {} of String => String)
    url, offset, limit = build_record_url(id, options)
    puts "default/generic record"

    r = {} of String => String
    r["code"] = "100"
    r["message"] = "This Must be Changed [generic record]"
    r.to_json
  end

  def each
    puts "to be implemented"
  end

  def size
    puts "to be implemented"
  end

  def first
    puts "to be implemented"
  end

  def last
    puts "to be implemented"
  end

  def [](i, j)
    puts "to be implemented"
  end

  def post( host : String, port = 80, path = "/",  request_body = "")
    begin
      if host.match(/^http(s)?:\/\//)
        get_http_response( host.sub(/http(s)?:\/\//, "") , port, path, request_body, "POST")
      else
        get_file_response(host)
      end
    end
  end

  def get( host : String, port = 80, path = "/",  request_body = "")
    begin
      if host.match(/^http(s)?:\/\//)
        get_http_response( host.sub(/http(s)?:\/\//, "") , port, path, request_body, "GET")
      else
        get_file_response(host)
      end
    end
  end

  def get_http_response( host : String, port = 80, path = "/",  request_body = "", method = "POST")
    begin
      client = HTTP::Client.new( host.as(String), port.as(Int32) )
      client.connect_timeout = 5 # seconds ?
      if method == "POST"
        response = client.post(path, headers: HTTP::Headers{"Content-Type" => "application/json"}, body: request_body.to_json )
      else
        response = client.get(path, headers: HTTP::Headers{"Content-Type" => "application/json"} )
      end

      case code = response.status_code
      when 200
        begin
          response.body
        rescue JSON::Error
          # TODO Error handling
          response.body
        end
      when 401
        error = Error.new(code: "401", message: "Invalid API key") #unauthorized
        return error
        raise error
      when 404
        error = Error.new(code: "404", message: "No Record(s) found") #Not Found
        return error
        raise error
      else
        puts response.body
        error =  Error.new(code: "500", message: "Unexpected HTTP status code: #{code}") #unknow Error
        return error
        raise error
      end
    rescue IO::Timeout
      puts "HTTP Timeout"
      error = Error.new(code: "408", message: "Error opening URL") #HTTP Timeout
      return error
      raise error     
    rescue e
      error = Error.new(code: "500", message: "Error opening URL [#{host}] #{e}") #HTTP Error
      return error
      raise error
    end 
  end

  def get_file_response( file : String)
    begin
      File.open( file )
    rescue 
      # TODO Error handling
      error = Error.new(code: "404", message: "Error opening file") # File Error
      return error
      raise error

    end
  end



  def query2options(env)
    options = {} of String => String
    params = env.params.query.to_h
    # halt env, 404, "No query found! add 'query=' to url" unless params.has_key?("query")

    options["from"] = params.fetch("from", "0")
    options["step"] = params.fetch("step", "10")
    options["host"] = params.fetch("host", "limo.libis.be")
    options["institution"] = params.fetch("institution", "KUL")
    options["sort"] = params.fetch("sort", "rank")
    options["database"] = params.fetch("database", "")
    options["timeout"] = params.fetch("timeout", "100")
    options["engines"] = (params.fetch("engines", "Primo")).downcase.capitalize
    options["query"] = params["query"]

    options
  rescue ex
    puts ex.message
    {} of String => String
  end
end
