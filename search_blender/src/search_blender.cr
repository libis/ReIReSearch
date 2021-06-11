require "kemal"
require "json"
#require "./search_blender/resolve"
require "./search_blender/results"
require "./search_blender/record"
require "logger"
require "./search_blender/config"
require "./search_blender/helpers/*"

module SearchBlender
  VERSION = "0.1.0"
  
  class RecordRequestHeader
    include JSON::Serializable
    include JSON::Serializable::Unmapped
    property id : String = ""
    property user : Hash(String, String) = Hash(String, String).new
  end

  class RequestHeader
    include JSON::Serializable
    include JSON::Serializable::Unmapped
    property q : String = ""
    property f : String = ""
    property s : String = ""
    property id : String = ""
    property engines : Hash(String, EnginesRequestHeader) = Hash(String, SearchBlender::EnginesRequestHeader).new
    property step : Int32 = 10
    property from : Int32 = 0
    property nav  : String = "first"
    property user : Hash(String, String) = Hash(String, String).new
  end
  
  class EnginesRequestHeader
    include JSON::Serializable
    include JSON::Serializable::Unmapped
    property timed_out : Bool?
    property took : Float64?
    property from : Int32 = 0
    property total : Int32 = 0
    property size : Array(Int32) =  Array(Int32).new
  end

  class Options
    def parse_options(ops)
      default_engine = convert_to_hash( "elastic" )
      #o = {} of String => String | Int32 | Hash(String, SearchBlender::EnginesRequestHeader)
      o = {} of String => String | Int32

      if ops.is_a?(HTTP::Params)
        q  = ops.has_key?("q")  ? ops.["q"] : ""
        f  = ops.has_key?("f")  ? ops.["f"] : "" 
        id = ops.has_key?("id") ? ops.["id"] : ""
        
        engines_hash = ops.has_key?("engines") ? convert_to_hash( ops["engines"] ) : default_engine
        
        ops.each {|k,v| o[k] = v unless k == "q" || k == "f" ||  k == "id" || k == "engines"  }
      end
      if ops.is_a?(SearchBlender::RequestHeader)

        q = ops.q ? ops.q : ""
        f = ops.f ? ops.f : ""
        id = ops.id ? ops.id : ""

        #if ops.engines
        #  engines_hash = ops.engines
        #else
        #  engines_hash = default_engine
        #end
        engines_hash = ops.engines ? ops.engines : default_engine

        ########################################################
        # The results must first be blended before the n-th page 
        # of the blended resultset can be calculated. 
        # Therefore FROM is not very useful in the blend,
        # NEXT and PREV would be more efficient.
        # Default values are set via class RequestHeader
   
        o["from"] = ops.from.to_s
        o["step"] = ops.step.to_s
        o["nav"]  = ops.nav.to_s.downcase # first / next/ prev
        o["s"]    = ops.s.to_s
    
        if ops.user
          o["user_ip"]      = ops.user.has_key?("ip")    ? ops.user["ip"]  : ""
          o["brepolstoken"] = ops.user.has_key?("brepolsid") ? ops.user["brepolsid"] : ""
          o["user_id"]      = ops.user.has_key?("id")    ? ops.user["id"] : ""
        else
          o["user_ip"]      = ""
          o["brepolstoken"] = ""
          o["user_id"]      = ""
        end
      end

      return {:q => q, :f => f, :id => id, :engines => engines_hash, :options => o}
    end
  
  end

  #FILE = File.new("./logs/search_blender_debug.log", "a")
  #writer=IO::MultiWriter.new(FILE, STDOUT)
  #dlog = Logger.new(writer)
   
  LOGGER = searchblender_logger()

  get "/" do
    "Hello World!"
  end

  get "/favicon.ico" do
  end

  get "/search" do |ctx|
    LOGGER.debug ( " ----- SearchBlender /search ")

    halt ctx, 503, "missing parameters" unless required_parameters(ctx.params.query.to_h.keys, ["q"])
    ops = Options.new.parse_options(ctx.params.query)
    q = ops[:q].as(String)
    f = ops[:f].as(String)
    engines = ops[:engines].as(Hash(String, SearchBlender::EnginesRequestHeader))
    options = ops[:options].as(Hash(String,  String | Int32 ) )

    data = Results.blender(q: q, f: f, options: options, engines: engines)
    
    ctx.response.content_type = "application/json"
    data.to_json
  end

  get "/blend" do |ctx|
    LOGGER.info ( " ----- SearchBlender /blend")
    halt ctx, 503, "missing parameters" unless required_parameters(ctx.params.query.to_h.keys, ["q","engines"])
    if ctx.params.query["q"].nil? && ctx.params.query["f"].nil?
      halt ctx, 503, "missing parameters"
    end

    LOGGER.info ( " ----- SearchBlender ctx.params.url :#{ctx.params.url}")
    LOGGER.info ( " ----- SearchBlender ctx.params.query :#{ctx.params.query}")
    LOGGER.info ( " ----- SearchBlender ctx.params.json :#{ctx.params.json}")
    
    ops = Options.new.parse_options(ctx.params.query)
    q = ops[:q].as(String)
    f = ops[:f].as(String)
    engines = ops[:engines].as(Hash(String, SearchBlender::EnginesRequestHeader))
    options = ops[:options].as(Hash(String,  String | Int32 ) )
    LOGGER.info ( " ----- SearchBlender BLENDER get engines: #{ engines }")

    ctx.response.content_type = "application/json"
    data = Results.blender(q: q, f: f, options: options, engines: engines)
    data.to_json
  end

  post "/blend" do |ctx|
    LOGGER.info ( " ----- SearchBlender /blend [POST]")
    LOGGER.info ( " json_header: #{ctx.params.json.to_json}")

    json_header = RequestHeader.from_json(ctx.params.json.to_json)
    if json_header.q.empty? && json_header.f.empty?
      halt ctx, 503, "q and f can't both be empty"
    end

    ops = Options.new.parse_options(json_header)
    q = ops[:q].as(String)
    f = ops[:f].as(String)
    engines = ops[:engines].as(Hash(String, SearchBlender::EnginesRequestHeader))    
    options = ops[:options].as(Hash(String,  String | Int32 ) )

    LOGGER.info ( " q: #{q}")
    LOGGER.info ( " f: #{f}")
    LOGGER.info ( " ----- SearchBlender BLENDER post engines: #{ engines }")

    ctx.response.content_type = "application/json"
    data = Results.blender(q: q,  f: f, options: options, engines: engines)
    
    data.to_json
  end

  get "/brepols" do |ctx|
    LOGGER.info ( " ----- SearchBlender /brepols")
    halt ctx, 503, "missing parameters" unless required_parameters(ctx.params.query.to_h.keys, ["q"])

    ops = Options.new.parse_options(ctx.params.query)
    q = ops[:q].as(String)
    f = ops[:f].as(String)
    options = ops[:options].as(Hash(String,  String | Int32 ) )
  
    options["engine"] = "brepols"
    ctx.response.content_type = "application/json"
    data = Results.resultset(q, f, options)
    data.to_json
  end

  get "/elastic" do |ctx|
    LOGGER.info ( " ----- SearchBlender /elastic")
    halt ctx, 503, "missing parameters" unless required_parameters(ctx.params.query.to_h.keys, ["q"])

    ops = Options.new.parse_options(ctx.params.query)
    q = ops[:q].as(String)
    f = ops[:f].as(String)
    options = ops[:options].as(Hash(String,  String | Int32 ) )

    options["engine"] = "elastic"

    ctx.response.content_type = "application/json"
    data = Results.resultset(q, f, options)
    data.to_json
  end

  get "/:id" do |ctx|
    halt ctx, 503, "missing parameters" unless required_parameters(ctx.params.url.keys, ["id"])

    ops = Options.new.parse_options(ctx.params.query)
    id = ops[:id].as(String)
    options = ops[:options].as(Hash(String,  String | Int32 ) )

    ctx.response.content_type = "application/json"
    ###############################################
    #data = Resolve.record(id, options)
    #data.to_json
  end

  get "/record/:id" do |ctx|
    LOGGER.info ( " ----- SearchBlender get record /record/:id")

    halt ctx, 503, "missing parameters" unless required_parameters(ctx.params.url.keys, ["id"])

    ops = Options.new.parse_options(ctx.params.query)
    #id = ops[:id].as(String)
    id = ctx.params.url["id"]
    options = ops[:options].as(Hash(String,  String | Int32 ) )

    ctx.response.content_type = "application/json"
    
    data = Record.get_record(id, options)

    if data.is_a?(SearchBlender::Record::ReIReSDoc)
      unless data.status_code == 200
        ctx.response.status_code = data.status_code.to_i
      end
        LOGGER.debug ( data.message )
        LOGGER.debug ( data.status_code )
    end
    LOGGER.debug (   data.to_json )
    data.to_json
  end

  post "/record" do |ctx|
    LOGGER.info ( " ----- SearchBlender get record [POST]")
    json_header = RequestHeader.from_json(ctx.params.json.to_json)
    if json_header.id.empty?
      halt ctx, 503, "id can't be empty"
    end

    ops = Options.new.parse_options(json_header)

    id = ops[:id].as(String)
    engines = ops[:engines].as(Hash(String, SearchBlender::EnginesRequestHeader))    
    options = ops[:options].as(Hash(String,  String | Int32 ) )

    ctx.response.content_type = "application/json"

    data = Record.get_record(id, options)
    
    LOGGER.debug ( " SearchBlender data.message #{data}")

    if data.is_a?(SearchBlender::Record::ReIReSDoc)
      unless data.status_code == 200
        ctx.response.status_code = data.status_code.to_i
      end
        LOGGER.debug ( data.message )
        LOGGER.debug ( data.status_code )
    end
    LOGGER.debug (   data.to_json )
    data.to_json

  end

end
  
def convert_to_hash(engines_string : String)
  engines_hash =  Hash(String, SearchBlender::EnginesRequestHeader).new
  engines_array = engines_string.split(",").uniq.map { |s| s.strip }
  engines_array.each { |e| 
    engines_hash[e.to_s] = SearchBlender::EnginesRequestHeader.from_json("{}") 
  }
  return  engines_hash
end


def required_parameters(available_params :  Array(String) | String, params : Array(String) )
  if params.is_a?(Array)
    ((params & available_params).size == params.size ) ? true : false
  end
end

Kemal.config.env = "production"
Kemal.run
