require "../search/search"

module SearchBlender
  module Results
    extend self

    DIRECTION_MULTIPLIER = { asc: 1, desc: -1 }

    class ReIResResultset 
        include JSON::Serializable
        include JSON::Serializable::Unmapped
        property timed_out : Bool = false
        property took : Float64 = 0
        property hits : Hits = SearchBlender::Results::Hits.from_json("{}")
        property aggregations : Hash(String, Aggregations) = Hash(String,  SearchBlender::Results::Aggregations).from_json("{}")
        property message : String | Nil = nil
    end

    #class HitSource
    #  include JSON::Serializable
    #  include JSON::Serializable::Unmapped
    #  property datePublished : String
    #  property name : MultiLingualValue
    #end

    #class MultiLingualValue
    #  property @value : String
    #  property @language: String
    #end

    class Hit
        include JSON::Serializable
        include JSON::Serializable::Unmapped
        property _index : String
        property _type : String
        property _id : String
        property _score : Float64?
        property _source : JSON::Any
        property sort : Array(String | Int32 | Int64 | Float64)?
    end

    class Hits
      include JSON::Serializable
      include JSON::Serializable::Unmapped
      property total : Int32 = 0
      property search_total : Int32  = 0
      property max_score : Float64?
      property step : Int32 = 10
      property from : Int32 = 0
      property hits : Array(Hit) = [] of SearchBlender::Results::Hit
    end 

    class Aggregation
      include JSON::Serializable
      include JSON::Serializable::Unmapped
      property key : JSON::Any? | String | Int64
      property key_as_string : JSON::Any? | String 
      property doc_count : JSON::Any? | Int32
    end

    class Aggregations
      include JSON::Serializable
      include JSON::Serializable::Unmapped
      property doc_count_error_upper_bound : Int32?
      property sum_other_doc_count : Int32?
      property value : Float64?
      property value_as_string : String?      
      property buckets : Array(Aggregation) = [] of SearchBlender::Results::Aggregation
    end
    
    class ReIResBlendedResultset 
      include JSON::Serializable
      include JSON::Serializable::Unmapped
      property timed_out : Bool = false
      property took : Float64 = 0
      property hits : Hits =  SearchBlender::Results::Hits.from_json("{}")
      property aggregations : Hash(String, SearchBlender::Results::Aggregations) = Hash(String, SearchBlender::Results::Aggregations).new
      property engines : Hash(String, SearchBlender::Results::EngineResultsetInfo) = Hash(String, SearchBlender::Results::EngineResultsetInfo).new
    end

    class EngineResultsetInfo
      include JSON::Serializable
      include JSON::Serializable::Unmapped
      property timed_out : Bool = false
      property took : Float64 = 0 
      property from : Int32 = 0
      property total : Int32 = 0

      property size : Array(Int32) =  [] of Int32
      property message : String | Nil = nil
    end

    LOGGER = searchblender_logger()

    #FILE = File.new("./logs/search_blender_debug.log", "a")

    def resultset(q : String, f : String, options : Hash(String, String | Int32))

      #writer=IO::MultiWriter.new(FILE, STDOUT)
      #dlog = Logger.new(writer)

      #logger.debug (" ----- SearchBlender::Results"     

      options["step"] = options.has_key?("step") ? options["step"] : "10"

      LOGGER.debug( "SearchBlender::Results : resultset - options")
      LOGGER.debug( "     #{ options }" )

      s = Search::Search.new(options)

      resultset = s.query("#{q}", "#{f}", options)
      # Only necessary if the search returns a JSON-string
      # Extra mapping necessary because JSON.parse 
      # returns type JSON::Any which has no method has_key?
      # result = ReIResResultset.from_json(resultset.to_json)

      # LOGGER.debug ( "   resultset   #{ resultset }" )
      # result = resultset
      # return ReIResResultset.from_json( result ) 
      return ReIResResultset.from_json( resultset )
    end
  

    def blender(q : String, f : String, options : Hash(String, String  | JSON::Any | Int32), engines : Hash(String, SearchBlender::EnginesRequestHeader ) )

      LOGGER.debug ( "SearchBlender::Results : blender - engines")
      LOGGER.debug ( "  #{ engines }" )
            
      LOGGER.debug ( "SearchBlender::Results : blender - options[]")
      LOGGER.debug ( "  option Input #{ options }" )
      
      blenderStarttime = Time.local

      r = SearchBlender::Results::ReIResBlendedResultset.from_json("{}") 
      r.engines = Hash(String, SearchBlender::Results::EngineResultsetInfo).new

      offset = options.has_key?("from") ? options["from"].to_i : 0
      step   = options.has_key?("step") ? options["step"].to_i : 10
      nav    = options.has_key?("nav")  ? options["nav"].to_s  : "first"
      sort   = options.has_key?("s")    ? options["s"].to_s    : "relevance"

      sort = "relevance" unless !sort.empty?

      e_options = options.clone
      #### Number of pages start counting from 0
      page_nr = offset / step

      LOGGER.debug ( "  option Current PAGE_NR #{ page_nr }" )

      case nav
      when "first"
        page_nr = 0
      when "next"
        page_nr = page_nr + 1
      when "prev"
        page_nr = page_nr - 1
      end
      
      offset = page_nr * step

      LOGGER.debug ( "  option Global FROM (offset) #{ offset }" )
      LOGGER.debug ( "  option Global STEP #{ step }" )
      LOGGER.debug ( "  option requested PAGE_NR #{ page_nr }" )

      ###########################################################################
      # SETUP NAVIGATION 
      ###########################################################################

      numberOfEngines = engines.keys.size
      all_engines_from = 0
      all_engines_total = 0
      engines.each_key do |engine|
        engine_params = engines[engine]
        all_engines_from = all_engines_from + engine_params.size[0, page_nr.to_i].reduce( 0 ) { |acc, i| acc + i }
        unless engine_params.total.nil?
          all_engines_total = all_engines_total + engine_params.total 
        end
      end

      LOGGER.debug ( "  count Global ALL_ENGINES_FROM #{ all_engines_from }" )
      LOGGER.debug ( "  count Global ALL_ENGINES_TOTAL #{ all_engines_total }" )
      if all_engines_total <= all_engines_from
        LOGGER.debug ( "  Reached end of resultslist for all engines" )
      end

      engines_keys = engines.keys

      #### Loop over all engines and get the resultset with the appropriate options ####
      #### count from and size per engine 
      engines.each_key do |engine|
        e_options["engine"] = engine
        engine_params = engines[engine]
        LOGGER.debug ( "SearchBlender::Results : blender Search for engine #{engine}" )

        from = engine_params.size[0, page_nr.to_i].reduce( 0 ) { |acc, i| acc + i }
        
        LOGGER.debug ( "SearchBlender::Results :  engine_params.total: #{engine_params.total} (counted from previous search)" )
        LOGGER.debug ( "SearchBlender::Results :  engine_params.size:  #{engine_params.size} (previous search)" )
        LOGGER.debug ( "SearchBlender::Results :  page_nr: #{page_nr}" )
        LOGGER.debug ( "SearchBlender::Results :  calculatede from engine_params.size: #{from} "   )

        e_options["from"] = from
        
        ############################################ Get Resultset ####################
        LOGGER.debug ( "  option #{engine} FROM #{ e_options["from"] }" )
        LOGGER.debug ( "    qeury #{q} " )
        # => THIS IS THE REAL SEARCH
        results = resultset(q, f, e_options)
        ###############################################################################

        if !results.nil?

          if  ( results.hits.hits.class == Array(SearchBlender::Results::Hit) )
            r.hits.hits.concat( results.hits.hits ) # => r.hits.hits will contain ALL retrieverd records in this search, unsorted !!!
            r.hits.search_total = r.hits.search_total + results.hits.total

            # If all elasticsearch results are already in previous resultpages
            # the results.hits.hits will be empty 
            # from == engine_params.total if all records are already retrieved
            # ==> engine_params.total > from 
            # Hits is also empy if the there are no results found 
            unless results.hits.hits.empty? && (engine_params.total > from || engine_params.total == 0)
              LOGGER.debug ( "SearchBlender::Results :  engine_params.total > from  => #{engine_params.total} > #{from} }") 
              r.hits.total = r.hits.total + results.hits.total
            end
          
            r.hits.step  = step
            # LOGGER.debug ( "SearchBlender::Results :  results.aggregations #{results.aggregations}" )

            results.aggregations.each_key do |aggr|
            #  LOGGER.debug ( "SearchBlender::Results :  results.aggregations key #{aggr}" )
              if r.aggregations.has_key?(aggr)
                results.aggregations[aggr].buckets.each do |bucket|
                  rBucket = r.aggregations[aggr].buckets.select { |rb| rb.key ==  bucket.key}
                  if  ( rBucket.size == 0 )
                    r.aggregations[aggr].buckets.push( bucket)
                  else
                    rBucket[0].doc_count = rBucket[0].doc_count.to_s.to_i + bucket.doc_count.to_s.to_i
                  end
                end
              else
                r.aggregations[aggr] = results.aggregations[aggr]
              end
              case aggr
              when "datePublished"
                dates =  r.aggregations[aggr].buckets.to_a.sort_by{ |b| b.key.to_s.to_i64 }
                unless dates.empty?
                  r.aggregations["min_datePublished"] = (SearchBlender::Results::Aggregations).from_json( 
                    %({ "value": #{ dates.first.key }, "value_as_string": "#{ dates.first.key_as_string }", "buckets": [] }) 
                  )
                  r.aggregations["max_datePublished"] = (SearchBlender::Results::Aggregations).from_json( 
                    %({ "value": #{ dates.last.key }, "value_as_string": "#{ dates.last.key_as_string }", "buckets": [] }) 
                  )
                end
              end
            end

            r_engine = SearchBlender::Results::EngineResultsetInfo.from_json("{}")
            r_engine.timed_out = results.timed_out
            r_engine.took      = results.took
            r_engine.from      = results.hits.from
            r_engine.total     = results.hits.total
            r_engine.message     = results.message 

            r.engines[ engine.to_s ] = r_engine
          end
        else
          LOGGER.debug ( "  results is NIL !!" )
        end
      end

      LOGGER.debug ( "SearchBlender::Results : r.hits.hits.size #{r.hits.hits.size}" )
      LOGGER.debug ( "SearchBlender::Results : sort records on #{sort}" )

      r.hits.hits = m_sort( r.hits.hits, sort ) 
#      r.hits.hits.each_index{  |i| LOGGER.debug( "SearchBlender::Results  : #{i} #{r.hits.hits[i]._score}  --- #{r.hits.hits[i]._id}") }

      r.hits.hits.each_index{  |i| LOGGER.debug( "SearchBlender::Results  : #{i} #{r.hits.hits[i].sort || nil}  --- #{r.hits.hits[i]._id} -- [#{r.hits.hits[i]._index.to_s}]") }
      sort

      r.hits.from = offset.to_i
      r.hits.hits = r.hits.hits[ 0, step]
      indexes = r.hits.hits.map { |h| h._index.to_s  }
      
      engines_config = JSON.parse ( SearchBlender.config.read_json_config("reires_search_engines.json") )

      engines.each_key do |e|

        LOGGER.debug ( "engines e #{e}")

       # r.engines[e].size = r.engines[e].size[0,page_nr]
        if engines_config.as_h.has_key?(e)
          #LOGGER.debug ( "r.engine #{e} indexes : #{ indexes } ")
          #LOGGER.debug ( "r.engine #{e} engines_config[e]['index'] : #{ engines_config[e]["index"] } ")

          # count the results that have an _index that mathes one off the regex from reires_search_engines.json
          # count = (indexes.select { |i| engines_config[e]["index"].as_a.select{ |ei| ei == i }.size > 0  }).size 
          count = (indexes.select { |i| engines_config[e]["index"].as_a.select{ |ei| Regex.new(ei.to_s).match(i) }.size > 0  }).size 
        
          r.engines[e].size = engines[e].size
          if (page_nr == r.engines[e].size.size)
            r.engines[e].size << count
          elsif (page_nr < r.engines[e].size.size)
            r.engines[e].size[page_nr.to_i] = count
          else
            r.engines[e].size << 0
          end
          LOGGER.debug ( "r.engine #{e} : #{ r.engines[e].size } ")
        else
          raise "Engine not defined in engine_config"
        end
      end

      # Put in all the engines that where removed related to the index provider:
      # Example : provider:KULeuven (This is part of the Elastic engine so it was not necessary to use the engine Brepols)
      engines_keys.each do |e|
        if ! r.engines.has_key?(e)
          r.engines[e.to_s] = SearchBlender::Results::EngineResultsetInfo.from_json("{}")
        end
      end

      blenderEndtime = Time.local

      took = (blenderEndtime - blenderStarttime).milliseconds 
      r.timed_out = false
      r.took = took.to_f

      result = r
      return result
    end

    def m_sort(items, sort_key, level = 0) 

      # LOGGER.debug ("SORT sort_key #{sort_key}")
      ########################################
      # Elastic Search bevat per record een array van sort values 
      # Elastic Search geeft geen sort-property als er gesorteerd wordt op _score
      # 
      # Brepols doet dit ook
      # Brepols geeft een lege array in sort als er gesorteerd wordt op _score
      # 
      # Het is een array omdat er op verschillende velden kan gesorteerd worden
      # Voorbeeld : sorteer op author => is eerst op author en daarna op relevance (_score)

      sort_order = -1

      items.sort do |this, that|

        this_val = get_sort_key(sort_key, this, level)
        that_val = get_sort_key(sort_key, that, level)
        sort_order = get_sort_order(sort_key)
      
      #  LOGGER.debug ("SORT SORT this #{this_val}")
      #  LOGGER.debug ("SORT SORT that #{that_val}")

        comparison = 0
        comparison = 1 if this_val.nil?
        comparison = -1 if that_val.nil?
        unless this_val.nil? || that_val.nil?
          if ["relevance", "date DESC", "date ASC"].includes? (sort_key)
            comparison =  this_val.as(Float64) <=> that_val.as(Float64) || 0
          else
            comparison = this_val.to_s.compare(that_val.to_s, case_insensitive: true)
          end
        end
        comparison = comparison * sort_order

      #  LOGGER.debug ("SORT SORT comparison #{comparison}")

        if comparison == 0
          #comparison =  0 if this._id.nil? && that._id.nil?
          #comparison =  1 if this._id.nil?
          #comparison = -1 if that._id.nil?
          #comparison =  this._id <=> that._id
          #Second sort option always relevance !!!!!!!!!!!!!!!!!!     
          #sort_key = "relevance"
          rlevel = 1
          rsort_order = -1
          rthis_val = get_sort_key("relevance", this, rlevel)
          rthat_val = get_sort_key("relevance", that, rlevel)
          comparison =  rthis_val.as(Float64) <=> rthat_val.as(Float64) || 0
          comparison = comparison * sort_order
        end
      
        next comparison
      end
    end

    def get_sort_order(sort_key)
      sort_order = -1
      case sort_key
      when "relevance"
        sort_order = -1
      when "date ASC"
        sort_order = 1
      when "date DESC"
        sort_order = -1
      when "title"
        sort_order = 1
      when "publicationdate"
        sort_order = 1
      when "publisher"
        sort_order = 1     
      else
        sort_order = -1
      end
      sort_order 
    end

    def get_sort_key(sort_key, this, level = 0)

      # Because the ReIReS data from Elastic search uses the ReIReS data
      # structure this mapping is almost the same
      #"relevance" : { "index": "_score", "order": "desc" },
      #"date ASC" : { "index": "datePublished", "order": "asc"},
      #"date DESC" :  { "index": "datePublished", "order": "desc"},
      #"title":  { "index": "name.@value.keyword",  "order": "asc"},
      #"publicationdate": { "index": "datePublished",  "order": "asc"},
      #"publisher":{ "index": "publisher.familyName.keyword", "order": "asc"}

      this_val = String.new
      if sort_key == "relevance"
        return this._score
      end

      this.sort.try do |ts|
        unless ts.empty?
          this_val = ts.[level] 
        end
        # LOGGER.debug ("Sort From this.sort #{this_val}")
      end

      if this_val.to_s.empty?
        case sort_key
        when "relevance"
          this_val = this._score
        when "date ASC"
          this_val = this._source["datePublished"]? ? this._source["datePublished"] : ""
        when "date DESC"
          this_val = this._source["datePublished"]? ? this._source["datePublished"] : ""
        when "title"
          this_val = this._source["name"]? ? this._source["name"] : ""
        when "publicationdate"
          this_val = this._source["datePublished"]? ? this._source["datePublished"] : ""
        when "publisher"
          this_val = this._source["publisher"]? ? this._source["publisher"] : ""
        else
          this_val = this._score
        end
        #LOGGER.debug ("Sort From sort_key #{this_val}")
      end
    #  LOGGER.debug (this_val)
    
      return this_val
    end

  end
end


def multi_sort(items, order)

  items.sort do |this, that|

    comparison = 0
    comparison = 1 if this._score.nil?
    comparison = -1 if that._score.nil?
    unless this._score.nil? || that._score.nil?
      comparison =  this._score.as(Float64) <=> that._score.as(Float64) || 0
    end
    comparison = comparison * -1
  
    if comparison == 0
      comparison = 0 if this._id.nil? && that._id.nil?
      comparison =  1 if this._id.nil?
      comparison = -1 if that._id.nil?
      comparison =  this._id <=> that._id
    end
    next comparison

  end
end


