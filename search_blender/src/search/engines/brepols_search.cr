require "./generic_search"
require "../query/brepols_query_generator"
require "uri"

class BrepolsResultset 
  include JSON::Serializable
  include JSON::Serializable::Unmapped

  @[JSON::Field(key: "Items")]
  property items : Array(BrepolsItem)

  @[JSON::Field(key: "ResultCount")]
  property resultCount : Int32

  @[JSON::Field(key: "Facet")]
  property facet : JSON::Any
end

class BrepolsItem
  include JSON::Serializable
  include JSON::Serializable::Unmapped  
  @[JSON::Field(key: "ResultNumber")]
  property resultNumber : Int32  

  @[JSON::Field(key: "Score")]
  property score : Float64 

  @[JSON::Field(key: "SchemaItem")]
  property schemaItem : JSON::Any

  @[JSON::Field(key: "SortingFeedback")]
  property sortingFeedback : Array(BrepolsItemSortingFeedback)

  @[JSON::Field(key: "sort")]
  property sort : Array(String | Float64) = Array(String | Float64).new 

end

class BrepolsItemSortingFeedback
  include JSON::Serializable
  include JSON::Serializable::Unmapped
  @[JSON::Field(key: "SortField")]
  property sortField : String

  @[JSON::Field(key: "SortValue")]
  property sortValue : Array(String | Float64)
end

# class BrepolsItemSource
#   include JSON::Serializable
#   include JSON::Serializable::Unmapped  
#   property identifier : String  
# end

class BrepolsHostConfig
  include JSON::Serializable
  include JSON::Serializable::Unmapped
  property host : String = "brepols"
  property index : String
  property port : Int32 = 80
  property path : String
  property api_key : String
  property user_ip : String
  property user_token : String
  property user_id : String
end

class BrepolsSearch < GenericSearch

  def initialize()
    super()
    @sort_map = Hash(String, Hash(String, JSON::Any)).new
    @aggs_map =  Hash(String, JSON::Any).new
    @index_map  = Hash(String, Array(String)).new
    @results_aggs_map =  Hash(String, JSON::Any).new

    @db_option = BrepolsHostConfig.from_json( SearchBlender.config.read_json_config("reires_brepols.json") )
    @iso_639 = JSON.parse ( SearchBlender.config.read_json_config("iso639.json") )
    datamodel = JSON.parse ( SearchBlender.config.read_json_config("reires_brepols_datamodel.json") )

    @sdPublisher =  JSON.parse(SearchBlender.config.datamodel_constants["sdPublisher"].to_json)

    @prefixid = JSON.parse(SearchBlender.config.datamodel_constants["prefixid"].to_json)

    @persistent_link_template = JSON.parse( SearchBlender.config.datamodel_constants["persistent_link_template"].to_json )

    ingestdata = {
      "provider": datamodel["provider"],
      "dataset": datamodel["dataset"],
      "license": datamodel["license"],
      "name": datamodel["genericRecordDesc"]
    }
       
    @provider_id   = datamodel["provider"].as_h["@id"].as_s || "Brepols"
    @provider_name = datamodel["provider"].as_h["name"].as_s || "Brepols"

    @dataset_id   = datamodel["dataset"].as_h["@id"].as_s || "IR"
    @dataset_name = datamodel["dataset"].as_h["name"].as_s || "Index Religiosus"

    @isBasedOn =   JSON.parse( build_isBasedOn(ingestdata).to_json )

    # @provider = "#{datamodel["provider"].as_h["@id"].as_s.upcase }"
    # @prefixid  =  "#{prefixid}_#{ @provider }_#{ datamodel["dataset"].as_h["@id"] }"
   
    mapping = JSON.parse (  SearchBlender.config.read_json_config("reires_brepols_mappings.json") )
    
    mapping.as_h.keys.each do |m|
      if m.to_s == "index"
        mapping[m].as_h.keys.each do |index|
          @index_map[index.to_s] = mapping[m].as_h[index].as_a.map do |i| i.to_s end
        end
      end 
      if m.to_s == "sort"
        mapping[m].as_h.keys.each do |v|
          @sort_map[v] =  mapping[m].as_h[v].as_h
        end
      end
      if m.to_s == "aggs"
        @aggs_map = mapping[m].as_h
      end
      if m.to_s == "results"
        @logger.debug ( "  mapping[m]: #{ mapping[m] }" )
        mapping[m].as_h.keys.each do |r_m|
          
          @logger.debug ( " r_m: #{r_m }" )

          if r_m.to_s == "aggs"

            @results_aggs_map = mapping[m].as_h[r_m].as_h
          end
        end
      end
    end

    @query_replacements = Array( Hash(String, String)).from_json( SearchBlender.config.read_json_config("reires_brepols_query_replacements.json") )

  end 

  def brepols_conf ( options = {} of String => String)
    host     = options.has_key?("host") ? options["host"]         : @db_option.host
    index    = options.has_key?("index") ? options["index"]       : @db_option.index
    port     = options.has_key?("port") ? options["port"].to_i    : @db_option.port
    path     = options.has_key?("path") ? options["path"].to_s    : @db_option.path

    api_key = options.has_key?("api_key") ? options["api_key"]          : @db_option.api_key

    user_ip    = options.has_key?("user_ip")      && !options["user_ip"].to_s.empty?      ? options["user_ip"]      : @db_option.user_ip
    user_token = options.has_key?("brepolstoken") && !options["brepolstoken"].to_s.empty? ? options["brepolstoken"] : @db_option.user_token 
    user_id    = options.has_key?("user_id")      && !options["user_id"].to_s.empty?      ? options["user_id"]      : @db_option.user_id
    
    if user_token == ""
      user_id = ""
    end

    # KU Leuven connects with IP 10-addresses o the ReIReS-server
    if user_ip =~ /^10\./ 
      user_ip = "USE FULL IP-ADDRESS"
    end

    [host, port, path, index, api_key, user_ip, user_token, user_id]
  end

  def build_url(q : String, f : String, options = {} of String => String)
    query_parser = Query::ReIReSLuceneParser.new

    query = ""
    filterhash = { query: "",  filter: [{ "FilterField": "index", "FilterValue": "terms" }]  }

    query      = BrepolsQueryGenerator.build_query( query_parser.parse(q) , q,  @index_map, @query_replacements) unless q.empty? # return bool_query
    filterhash = BrepolsQueryGenerator.build_filter( query_parser.parse(f) , f,  @index_map, @query_replacements) unless f.empty? # return bool_query

    filter = filterhash[:filter]
    filter_query = filterhash[:query]  # filter quer is used for provider,dataset and publication date range

    offset = options.has_key?("from") ? options["from"].to_i : 0
    limit  = options.has_key?("step") ? options["step"].to_i : 10
    sort   = options.has_key?("s")    ? options["s"].to_s    : "relevance"   

    q_sort = BrepolsQueryGenerator.build_sort(sort, @sort_map)

    host, port, path, index, api_key, user_ip, user_token, user_id = brepols_conf(options)

    request_body = {} of String => String | Int32 | Array(NamedTuple(FilterField: String, FilterValue: String))
    request_body["ApiKey"]    = api_key
    request_body["UserIP"]    = user_ip
    request_body["UserToken"] = user_token
    request_body["UserID"]    = user_id
    request_body["PageFirstRecord"] = offset.to_i.to_s
    request_body["PageSize"]        = (limit.to_i).to_s

    parsed_query = query
    unless filter_query.nil? || filter_query.empty? 
      if query.empty?
        parsed_query = filter_query
      else
        parsed_query = "(#{query}) AND (#{filter_query})"
      end
    end    

    @logger.info( "BrepolsSearch : search for parsed_query #{parsed_query} ")

    unless filter.nil? || filter.empty? 
      request_body["Filters"] = filter
    end

    request_body["SearchQuery"] = "#{parsed_query}"

    @logger.info( "BrepolsSearch : sort  #{sort} ")
    unless q_sort.nil?
      request_body["Sort"] = q_sort
    end
    
    @logger.info( "BrepolsSearch : request_body #{ request_body.to_json} ")
    @logger.info( "BrepolsSearch : search for parsed_query #{parsed_query} ")

    request_headers = HTTP::Headers{"Content-Type" => "application/json"}
    [host, port, path, request_headers, request_body, offset, limit]

  rescue e
    raise e
  end

  def query(q, f, options = {} of String => String)
  
    results = SearchBlender::Results::ReIResResultset.from_json("{}")

    @logger.debug( "BrepolsSearch : query options #{options } ")

    # Als er wordt beperkt op provider en deze is niet Brepols heeft het geen nut om te gaan zoeken in Brepols
    # TODO wat als er meerdere queires worden gecombineerd ?????
    # Hiervoor moet eerst de querie worden geanaliseerd via pegmatite om daarna te kunnen beslissen welk deel er
    # naar Brepols request moet wordne opgenomen.
    # voorbeeld (any:Antonio AND provider:KULeven) OR (title:deo ANR provider:Brepols)
    #
    # Dezelfde opmerking voor Dataset 
    #
    hasProviderFilter = f.partition(/[\(\[]*provider:[^:]*/)[1].gsub(/provider:/, "")
    hasProviderQuery  = q.partition(/[\(\[]*provider:[^:]*/)[1].gsub(/provider:/, "")
    unless ( hasProviderQuery.empty?  && hasProviderFilter.empty? )

      @logger.debug( "BrepolsSearch : query or filter contains provider index provider: ")
      @logger.debug( "BrepolsSearch : hasProviderFilter #{hasProviderFilter.match(/Brepols/i)}")
      @logger.debug( "BrepolsSearch : hasProviderQuery #{hasProviderQuery.match(/Brepols/i)}")

      providerRegex = /#{@provider_id}|#{@provider_name}/i

      if ( hasProviderFilter.match(providerRegex).nil? && hasProviderQuery.match(providerRegex).nil? )
        @logger.debug( "BrepolsSearch : query or filter contains provider index. Brepols is not included as value for this filter. No search is needed")
        results.hits = SearchBlender::Results::Hits.from_json("{}")
        return results.to_json
      end
    end
 
    hasDatasetQuery  = q.partition(/[\(\[]*dataset:[^:]*/)[1].gsub(/dataset:/, "")
    hasDatasetFilter = f.partition(/[\(\[]*dataset:[^:]*/)[1].gsub(/dataset:/, "")

    unless hasDatasetQuery.empty?  && hasDatasetFilter.empty? 

      #datasetRegex = /^"?#{@dataset_id}"?$|^"?#{@dataset_name}"?$/i
      datasetRegex = /#{@dataset_id}|#{@dataset_name}/i
      
      if ( hasDatasetFilter.match(datasetRegex).nil? && hasDatasetQuery.match(datasetRegex).nil? )
        @logger.debug( "BrepolsSearch : query or filter contains dataset index. IR (or other Brepols dataset) is NOT included as value for this filter. No search is needed")
        results.hits = SearchBlender::Results::Hits.from_json("{}")
        return results.to_json
      end
    end

    sort   = options.has_key?("s") ? options["s"] : "relevance"
    host, port, path, request_headers, request_body, offset, limit = build_url(q, f, options)

    @logger.debug ( "BrepolsSearch search FROM(offset) #{offset} STEP(limit) #{ limit }" )
    @logger.debug ( "BrepolsSearch search q: #{q} ")
    @logger.debug ( "BrepolsSearch : http://#{host}:#{port}#{path}  =>" )
    @logger.debug ( request_body.to_json )
    @logger.debug ( "---------------------------------------------------" )

    searchStarttime = Time.local
    begin
     
      data = post(host: "http://#{host.as(String)}" , path: path.to_s, request_body: request_body )
      
      unless data.is_a?(Error)
        bresult = BrepolsResultset.from_json(data)
        bresult.items = parse_sort( bresult.items, sort )

        bhits = parse_hits( bresult.items )
        aggs  = parse_aggs( bresult.facet )

        @logger.debug( "BrepolsSearch options      : #{options}" )
        @logger.debug( "BrepolsSearch bhits.size         : #{bhits.size}" )
        @logger.debug( "BrepolsSearch options[from]      : #{options["from"]}" )
        @logger.debug( "BrepolsSearch bresult.resultCount: #{bresult.resultCount}" )
        
        if bhits.size == 0 && bresult.resultCount > 0 && bresult.resultCount  > options["from"].to_i
          user_ip      = options.has_key?("user_ip")      ? options["user_ip"].to_s      : ""
          brepolstoken = options.has_key?("brepolstoken") ? options["brepolstoken"].to_s : ""
          user_id      = options.has_key?("user_id")      ? options["user_id"].to_s      : ""

          results.message = "Brepols Error: No Access to the items [ip: #{ user_ip }, UserToken: #{ brepolstoken }, ID: #{ user_id } ] #{bresult.resultCount} record found"
          
          @logger.info( "BrepolsSearch : #{  results.message }")
        end

        unless bhits.size == 0 
          if bresult.resultCount > 0 
              agg = SearchBlender::Results::Aggregations.from_json("{}")
              agg.doc_count_error_upper_bound = 0
              agg.sum_other_doc_count = 0
              bucket = SearchBlender::Results::Aggregation.from_json("{}")
              bucket.key           =   @provider_id
              bucket.key_as_string =   @provider_name
              bucket.doc_count     =  bresult.resultCount
              agg.buckets = [bucket]
              aggs["provider"] = agg
              
              agg = SearchBlender::Results::Aggregations.from_json("{}")
              agg.doc_count_error_upper_bound = 0
              agg.sum_other_doc_count = 0
              bucket = SearchBlender::Results::Aggregation.from_json("{}")
              bucket.key           =  @dataset_id
              bucket.key_as_string =  @dataset_name
              bucket.doc_count     =  bresult.resultCount
              agg.buckets = [bucket]  
              aggs["dataset"] = agg
          end
          # If no hits (because no access) aggr will not be inlcuded
          @logger.info( "BrepolsSearch aggs : #{  aggs }")

          results.aggregations = Hash(String,  SearchBlender::Results::Aggregations).from_json( aggs.to_json )
        end
        
        begin
          @logger.debug( "BrepolsSearch try to parse from_json")
          results.hits = SearchBlender::Results::Hits.from_json("{}")
        rescue
          @logger.error( "BrepolsSearch parse from_json was a disaster !!")
        end

        results.hits.from = offset.as(Int32)
        results.hits.step = limit.as(Int32)
        results.hits.total = bresult.resultCount
        results.hits.max_score =  0
        
        results.hits.hits = Array(SearchBlender::Results::Hit).from_json( bhits.to_json )
       
        searchEndtime = Time.local
        took = (searchEndtime - searchStarttime).milliseconds 

        results.timed_out = false
        results.took = took.as(Int32).to_f
      else
        results.message = "Brepols Error: #{data.message}"
      end
      # @logger.debug( "--> Brepols results: #{results.to_json}" )
      
      results.to_json
    end
  end

  private def build_isBasedOn(ingestdata)
      {
        "@type" => "CreativeWork",
        "@id" => "#{@prefixid}_#{ ingestdata["provider"]["@id"] }_#{ ingestdata["dataset"]["@id"]}",
        "license" => ingestdata["license"],
        "name" => ingestdata["name"],
        "provider" => ingestdata["provider"],
        "isPartOf" => ingestdata["dataset"]
      }
  end

  private def parse_sort(items, sort) 
    q_sort = BrepolsQueryGenerator.build_sort(sort, @sort_map)  || "#SCORE DESC"
    q_sort_a = q_sort.split(/,/).map {|s| s.strip  }
    items.map { |i|
      r = q_sort_a.map { |s| 
        # Elastic search returns date sortings as  milliseconds-since-the-epoch
        # transform format of the value if sorting is "publicationdate DESC/ASC",
        i.sortingFeedback.select{ |sf| 
          sf.sortField == s 
        }.map { |s| 
          if s.sortField.includes?("publicationdate") 
            s.sortValue.map { |d| Time.utc( d.to_i, 1, 1, 0, 0, 0).to_unix_ms.to_f }
          else 
            s.sortValue 
          end
        }
      }
      i.sort = r.flatten
      i
    }
    items      
  end

  private def parse_hits(items)
    hits = items.map { |item|
      item_score = item.score.to_s.to_f
      item_source = item.schemaItem.as_h
      # id = item_source["identifier"].to_s
      id = "#{@isBasedOn["@id"]}_#{item_source["identifier"].to_s}"
      
      hit = Hash(String, String | Float64 | JSON::Any | Hash(String, JSON::Any) | Array(String| Float64)).new

      #item_source["sdPublisher"]  = JSON.parse(@sdPublisher.to_json)
      item_source["sdPublisher"]  = @sdPublisher
      #item_source["provider"]     = JSON.parse(@provider.to_json)
      item_source["isBasedOn"]    = @isBasedOn
      item_source["@id"]          = JSON.parse( id.to_json )
      item_source["sameAs"]       = JSON.parse( item_source["url"].to_json )

      item_source["url"]          = JSON.parse( @persistent_link_template.to_s.gsub(/<#record_id>/, id).to_json )

      hit["_index"] =  @db_option.index
      hit["_type"]  = "_doc"
      hit["_id"]    = id.to_s
      # TODO normalisation relevance scoring
      #hit["_score"] = item_score
      hit["_score"] = item_score * 5
      
      hit["_source"]= item_source
      # TODO sorting via sort-array
      #hit["sort"] = Array(String).new
    
      hit["sort"] = item.sort.to_a
      SearchBlender::Results::Hit.from_json( hit.to_json )
    }
    hits
  end

  private def parse_aggs(facet)
    @logger.debug ("BrepolsSearch :  parse_aggs facet : #{facet}")   
    aggregations = Hash(String, SearchBlender::Results::Aggregations).new

    # Check for object that containt key Native
    iso_639_obj = @iso_639.as_a.select{ |e| e.as_h.has_key?("Native") }
    @logger.debug ("BrepolsSearch : convert text to iso code with iso_639_obj : #{ iso_639_obj }")   
    
    facet["FacetFields"].as_a.each do |f|
      @logger.debug ("BrepolsSearch : facet[\"FacetFields\"] f  : #{ f }")   
      @logger.debug ("BrepolsSearch : facet[\"FacetFields\"] f[\"FieldDisplay\"] : #{ f["FieldDisplay"].to_s  }")   

        aggs_key = map_aggrs( f["FieldDisplay"].to_s )
        unless aggs_key.nil? 
          agg = SearchBlender::Results::Aggregations.from_json("{}")
          agg.doc_count_error_upper_bound = 0
          agg.sum_other_doc_count = 0

          case aggs_key
          when "inLanguage"
            buckets = f["Children"].as_a.map { |fv|
                      bucket = SearchBlender::Results::Aggregation.from_json("{}")
                      iso_code = fv["DisplayLabel"]
                      iso_obj = iso_639_obj.select { |e| e["Native"] == fv["DisplayLabel"]  }
                      if iso_obj.nil? ||  iso_obj.empty? 
                        iso_obj = iso_639_obj.select { |e| e["alpha2"] == fv["DisplayLabel"]  }
                      end
                      if iso_obj.nil? ||  iso_obj.empty? 
                        @logger.info ( " Missing langauge code in iso_639.json : Native: \"#{fv["DisplayLabel"]}\"" )
                      else
                        iso_code  = iso_obj[0]["alpha3-b"]
                        iso_label = iso_obj[0]["Native"]
                      end
                      #bucket.key           =  fv["DisplayLabel"]
                      bucket.key           =  iso_code
                      bucket.key_as_string =  iso_label
                      bucket.doc_count     =  fv["Count"]
                      bucket
                  }
          when "datePublished"                  
            buckets = f["Children"].as_a.map { |fv|
              bucket = SearchBlender::Results::Aggregation.from_json("{}")
              bucket.key           =  Time.utc(fv["DisplayLabel"].to_s.to_i, 1, 1, 0, 0, 0).to_unix_ms
              bucket.key_as_string =  fv["DisplayLabel"]
              bucket.doc_count     =  fv["Count"]
              bucket
            }
          else
            buckets = f["Children"].as_a.map { |fv|
                      bucket = SearchBlender::Results::Aggregation.from_json("{}")
                      bucket.key           =  fv["DisplayLabel"]
                      bucket.key_as_string =  fv["DisplayLabel"]
                      bucket.doc_count     =  fv["Count"]
                      bucket
                  }
          end

          agg.buckets = buckets
          aggregations[ aggs_key.to_s ] = agg        
        end
    end

    aggregations
  rescue e
    puts e.message
    puts e.backtrace.join("\n")
    raise Error.new(code: "parse_error", message: "Parse Aggregations error")
  end

  private def map_aggrs(k)
    # mapping of aggregations from config-file reires_brepols_mapping.json
    @logger.debug ("BrepolsSearch : map_aggrs map #{k}" )
    @logger.debug ("BrepolsSearch : map_aggrs @results_aggs_map #{ @results_aggs_map }" )


    if @results_aggs_map.has_key?(k)
      @logger.debug ("BrepolsSearch : map_aggrs #{k} => #{ @results_aggs_map[k] }" )
      @results_aggs_map[k]
    else
      @logger.debug ("BrepolsSearch : map_aggrs #{k} => NILNILNIL" )
      nil
    end
  end

  def build_record_url(id, options = {} of String => String)

    offset = options.has_key?("from") ? options["from"].to_i : 0
    limit  = options.has_key?("step") ? options["step"].to_i : 10
    sort   = options.has_key?("s") ? options["s"] : "relevance"   

    host, port, path, index, api_key, user_ip, user_token, user_id = brepols_conf(options)

    request_body = {} of String => String | Int32
    request_body["ApiKey"]    = api_key
    request_body["UserIP"]    = user_ip
    request_body["UserToken"] = user_token
    request_body["UserID"]    = user_id
    
    request_body["PageFirstRecord"] = 0
    request_body["PageSize"] = (limit.to_i * 10).to_s

    request_body["SearchQuery"] = "any:\"#{id}\""

    @logger.debug( "BrepolsSearch : request_body #{ request_body} ")

    request_headers = HTTP::Headers{"Content-Type" => "application/json"}
    [host, port, path, request_headers, request_body, offset, limit]

  rescue e
    raise e
  end


  def record(id, options = {} of String => String)

    host, port, path, request_headers, request_body, offset, limit = build_record_url(id, options)

    # "any:\"BREPOLIS:IR:ARTL:365306\""
    @logger.debug ( request_body )

    begin

      @logger.debug ( "  brepols search  http://#{host.as(String)}" )
      
      data = post(host: "http://#{host.as(String)}", path: path.to_s, request_body: request_body )
      
      @logger.debug ( "data")
      @logger.debug ( data )

      doc = SearchBlender::Record::ReIReSDoc.from_json("{}")

      unless data.is_a?(Error)
        bresult = BrepolsResultset.from_json(data)
        @logger.debug ( " bresult.items.empty? : #{ bresult.items.empty?}" )
        unless bresult.items.empty?
          bhits  = parse_hits( bresult.items )
          doc._id =  bhits[0]._id
          doc._source = bhits[0]._source 
        else
          if bresult.items.size == 0 && bresult.resultCount > 0 
            user_ip      = options.has_key?("user_ip")      ? options["user_ip"].to_s      : ""
            brepolstoken = options.has_key?("brepolstoken") ? options["brepolstoken"].to_s : ""
            user_id      = options.has_key?("user_id")      ? options["user_id"].to_s      : ""
  
            doc.message = "Brepols Error: No Access to the items [ip: #{ user_ip }, UserToken: #{ brepolstoken }, ID: #{ user_id } ] #{bresult.resultCount} record found"
            doc.status_code = 401
          else
            doc.message = "Brepols Error: No Record(s) found"
          end
          doc._id = "#{id}"
        end
      else
        @logger.debug ( "Brepols Error: Search for #{id}" )
        doc.message = "Brepols Error: Search for #{id}"
        doc.status_code = 500
      end
      doc
    end  
  end

end
