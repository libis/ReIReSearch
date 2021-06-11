require "uri"
require "json"
require "./generic_search"
require "../query/elastic_query_generator"

class ElasticResultset 
  include JSON::Serializable
  include JSON::Serializable::Unmapped
  property timed_out : Bool
  property took : Float64
  property hits : ElasticHits
  property aggregations : Hash(String, ElasticAggregations | ElasticMinMax)
end
class ElasticHits
  include JSON::Serializable
  include JSON::Serializable::Unmapped
  property total : ElasticTotal
  property max_score : Float64? | String
  property hits : Array(ElasticHit)
  
end
class ElasticTotal
  include JSON::Serializable
  include JSON::Serializable::Unmapped
  property value : Int32 = 0
  property relation : String
end

class ElasticHit
  include JSON::Serializable
  include JSON::Serializable::Unmapped
  property _index : String
  property _type : String
  property _id : String 
  property _score : Float64?
  property _source : JSON::Any
  property sort :  Array( String | Int64 | Float64 | Nil ) ?
end

class ElasticDoc
  include JSON::Serializable
  include JSON::Serializable::Unmapped
  property _index : String
  property _type : String
  property _id : String
  property _version : Int32
  property _seq_no : Int32
  property _primary_term : Int32
  property found : Bool
  property _source : JSON::Any
end

class ElasticAggregations
  include JSON::Serializable
  include JSON::Serializable::Unmapped
  property doc_count_error_upper_bound : Int32 = 0
  property sum_other_doc_count : Int32 = 0
  property buckets : Array(SearchBlender::Results::Aggregation)
end

class ElasticMinMax
  include JSON::Serializable
  include JSON::Serializable::Unmapped
  property value : Float64 | Nil
  property value_as_string : String | Nil
end


class ElasticConfig
  include JSON::Serializable
  include JSON::Serializable::Unmapped
  property host : String = "elasticsearch"
  property port : Int32 = 9200
  property es_index : String = "reires_test"
end


class ElasticSearch < GenericSearch

  def initialize()
    super()
    @sort_map = Hash(String, Hash(String, JSON::Any)).new
    @aggs_map =  Hash(String, JSON::Any).new
    @index_map  = Hash(String, Array(String)).new
    @query_replacements = Array( Hash(String, String)).new

    mapping = JSON.parse ( SearchBlender.config.read_json_config("reires_elastic_mappings.json") )

    mapping.as_h.keys.each do |m|
      if m.to_s == "index"
        mapping[m].as_h.keys.each do |index|
          @index_map[index.to_s.downcase] = mapping[m].as_h[index].as_a.map do |i| i.to_s end
        end
      end 
      if m.to_s == "sort"
        mapping[m].as_h.keys.each do |v|
          @sort_map[v] =  mapping[m].as_h[v].as_h
        end
      end
      if m.to_s == "aggs"
        @aggs_map = mapping[m].as_h
        @logger.debug ( "   @aggs_map #{  @aggs_map }" )
        @logger.debug ( "   @aggs_map.class #{  @aggs_map.class }" )
      end
    end

    @query_replacements = Array( Hash(String, String)).from_json( SearchBlender.config.read_json_config("reires_elastic_query_replacements.json") )

  end 

  def elastic_conf ( options = {} of String => String)

    db_option = ElasticConfig.from_json( SearchBlender.config.read_json_config("reires_elastic.json") )
    host     = options.has_key?("host") ? options["host"]         : db_option.host
    port     = options.has_key?("port") ? options["port"].to_i    : db_option.port
    es_index = options.has_key?("es_index") ? options["es_index"] : db_option.es_index

    [host, port, es_index]
  end

  def build_url(q : String, f : String, options = {} of String => String)  
    query_parser = Query::ReIReSLuceneParser.new
    query = ""
    filter = ""

    query  = EsQueryGenerator.build_query( query_parser.parse(q) , q ,  @index_map, @query_replacements ) unless q.empty? # return bool_query
    filter = EsQueryGenerator.build_query( query_parser.parse(f) , f ,  @index_map, @query_replacements ) unless f.empty? # return bool_query
    
    @logger.debug ( " build_url : query            #{ query }" )

#    query = map_index_fields(query)
#    filter = map_index_fields(filter)
#    @logger.debug ( " build_url : map_index_fields #{ query }" )

    unless filter.empty?
      unless query.empty?
        parsed_query = { "bool": { "must": query , "filter": filter } } 
      else
        parsed_query = { "filter": filter } 
      end
    else
      parsed_query = { "bool": { "must": query } }
      # parsed_query = query ????
    end

    ### TODO read in memory of this db_options (reduce IO access )
    # Wel handig voor testen! Geen restart nodig .
    host, port, es_index = elastic_conf(options)

    offset   = options.has_key?("from") ? options["from"].to_i    : 0
    limit    = options.has_key?("step") ? options["step"].to_i    : 10
    sort_option = options.has_key?("s")    ? options["s"].to_s  : "relevance"
    
    sort_index = "_score"
    sort_order = "desc"
        
    sort = [ {sort_index => {"order": sort_order}} ]

    unless sort_option == "relevance"
      if @sort_map.has_key?(sort_option)
        sort_index =  @sort_map[sort_option]["index"].to_s
        sort_order =  @sort_map[sort_option]["order"].to_s
        sort.unshift ( {sort_index => {"order": sort_order}} )
      end
    end

    path = "/#{es_index}/_search?"
    # url = "http://#{host}:#{port}#{path}"

    request_body = {} of String => String
    request_headers = HTTP::Headers{"Content-Type" => "application/json"}

    request_body = {
      "from": offset, 
      "size": limit,
      "track_total_hits": true,
      "query": parsed_query,
      "sort": sort,
      "aggs": @aggs_map
    }
    @logger.debug ( " ElasticSearch build_url request_body : #{request_body.to_json}" )

    [host, port, path, request_headers, request_body, offset, limit]
  rescue e
    raise e
  end

  def query(q, f, options = {} of String => String)

    host, port, path, request_headers, request_body, offset, limit = build_url(q, f, options)

    @logger.debug ( "  elastic search FROM(offset) #{offset} STEP(limit) #{ limit }" )
    @logger.debug ( "  search for #{ request_body.to_pretty_json }" )

    begin
      #data = get(host = "./src/tests/elastic_result.json")

      @logger.debug ( "  elastic search host http://#{host.as(String)}" )

      data = post(host: "http://#{host.as(String)}" , port: port.as(Int32), path: path.to_s, request_body: request_body )

      results = SearchBlender::Results::ReIResResultset.from_json("{}")

      @logger.debug ( "  elastic data  #{ data.to_s[0,250] }" )

      unless data.is_a?(Error)

        eresult = ElasticResultset.from_json(data)

        # @logger.debug ( "  elastic search eresult  #{ eresult.to_json }" )

        results.took       = eresult.took
        results.timed_out  = eresult.timed_out
  
        @logger.debug ( "  elastic eresult.hits.total  #{ eresult.hits.total.value }" )

        results.hits       = SearchBlender::Results::Hits.from_json("{}")
        # results.hits.total = eresult.hits.total 
        results.hits.total = eresult.hits.total.value
        results.hits.hits  = Array( SearchBlender::Results::Hit).from_json( eresult.hits.hits.to_json )
        # @logger.debug ( "  elastic searche result.hits.hits " )
        

        results.hits.from  = offset.as(Int32)
        results.hits.step  = limit.as(Int32)
    

        results.aggregations = Hash(String,  SearchBlender::Results::Aggregations).from_json( eresult.aggregations.to_json )
      else
        @logger.debug ( "Elastic Error: #{data.message}" )
        results.message = "Elastic Error: #{data.message}"
      end

      results.to_json
      
    end    
  end

  def parse_results( data : String)
    result = data
    result
  end

  def build_record_url(id, options = {} of String => String)
    host, port, es_index = elastic_conf(options)

    request_body = {} of String => String
    request_headers = HTTP::Headers{"Content-Type" => "application/json"}

    path = "/#{es_index}/_doc/#{id}?"
    @logger.debug ( "  elastic search path #{path} " )
    [host, port, path, request_headers, request_body]
  end

  def record(id, options = {} of String => String)
    host, port, path, request_headers, request_body = build_record_url(id, options)

    @logger.debug ( "  elastic search get record #{id} " )

    begin

      @logger.debug ( "  elastic search host http://#{host.as(String)}" )
      
      data = get(host: "http://#{host.as(String)}" , port: port.as(Int32), path: path.to_s, request_body: request_body )
      
      @logger.debug ( "data" )
      @logger.debug ( data )

      doc = SearchBlender::Record::ReIReSDoc.from_json("{}")

      unless data.is_a?(Error)
        edoc = ElasticDoc.from_json(data)
        @logger.debug ( "edoc : #{edoc}" )
        #@logger.debug ( "edoc._id : #{edoc._id}" )
        doc._id = edoc._id
        doc._source = edoc._source
      else
        doc._id = "#{id}"
        # @logger.debug ( "Elastic Error: #{ error } ")
        @logger.debug ( "Elastic Error : data.message #{data.message} - data.code #{data.code}" )
        doc.message = "Elastic Error: #{data.message}"
        doc.status_code = data.code.to_i
      end
      doc
    end  
  end
end
