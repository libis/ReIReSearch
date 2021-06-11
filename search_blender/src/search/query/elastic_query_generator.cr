module EsQueryGenerator
  VERSION = "0.1.0"

  alias EsQueryString = Hash(Symbol, Hash(Symbol, String | Array(String) ))
  alias EsExistsString = Hash(Symbol, Hash(Symbol, String))
  alias QueryCompound = EsQueryString | EsExistsString | Hash(Symbol, Hash(Symbol, Array(EsQueryGenerator::QueryCompound)) ) 

  @@spacer = 0

  ###### TODO : implement boolean operator precedence 
  # https://lucidworks.com/post/why-not-and-or-and-not/
  # https://i.stack.imgur.com/SUwCq.png

  @@coutnt = 0

  LOGGER = searchblender_logger()

  def self.build_query( tokens : Array( Pegmatite::Token  ) , query : String, index_map, query_replacements = Array( Hash(String, String)).new )
    begin
      query = create_query(tokens, query)
#      LOGGER.debug ( "EsQueryGenerator build_query : query            #{ query }" )
#      LOGGER.debug ( "EsQueryGenerator build_query : type            #{ typeof(query) }" )
      query = post_processing(query, index_map, query_replacements)
     
      LOGGER.debug ( "EsQueryGenerator build_query : query(map_index) #{query }" )
      query
    rescue ex
      LOGGER.error "ERROR EsQueryGenerator build_query #{ex.message}"
      return ""
    end
  end  

  def self.create_query( tokens : Array( Pegmatite::Token  ) , query : String)
    logger = Logger.new(STDOUT)
    logger = searchblender_logger()

    queries = [] of QueryCompound
    booleanType = ""
    operator = ""
    
    #queries_begin = 0;
    #queries_end = 0;
    #query_begin = 0;
    #query_end = 0;  
    parsed_tokens_begin = 0  
    parsed_tokens_end   = 0  

    logger.debug ("EsQueryGenerator Start creating query:")

    tokens.each_with_index do |t, i|
      @@coutnt = @@coutnt+1
      if @@coutnt > 4000
        logger.error ("ERROR PARSING EsQueryGenerator  tokens !!!!!! countnt #{@@coutnt} !!!!!!!!!")
        exit
      end

      if ( parsed_tokens_begin > t[1]) 
        next
      end
      
      tokens_begin = t[1];
      tokens_end =  t[2];

#      logger.debug ("  tokens_begin #{tokens_begin}")
#      logger.debug ("EsQueryGenerator  t_parsing #{ t[0] } : #{ query.byte_slice( t[1], t[2]-t[1] ) }  --- #{t[1]} ... #{t[2]}")

      case t[0].to_s 
      when "queries_blok"
        selectedtokens = tokens.select { |to| ( tokens_begin <= to[1] &&  to[2]  <=  tokens_end ) }
        selectedtokens.shift
#        logger.debug ("EsQueryGenerator queries_blok - qtokens #{selectedtokens}")
#        logger.debug ("EsQueryGenerator queries_blok - #{query}")
        result = create_query( selectedtokens,  query )
#        logger.debug ("EsQueryGenerator queries_blok - result #{result}")
        parsed_tokens_begin = tokens_end
        #return result
        queries << result

      when "queries"
        selectedtokens = tokens.select { |to| ( tokens_begin <= to[1] &&  to[2]  <=  tokens_end ) }
        selectedtokens.shift
        @@spacer += 1
        #logger.debug ("#{ t[0] } : #{ query[ t[1]...t[2] ] }  --- #{t[1]} ... #{t[2]}")
#        logger.debug ("EsQueryGenerator queries - qtokens #{selectedtokens}")
#        logger.debug ("EsQueryGenerator queries - #{query}")

        bool_query = create_query( selectedtokens,  query )
        parsed_tokens_begin = tokens_end
#        logger.debug ( "EsQueryGenerator queries => bool_query \n#{bool_query}" )
#        logger.debug ( "EsQueryGenerator queries => bool_query.to_pretty_json \n#{bool_query.to_pretty_json}" )

        queries << bool_query

        @@spacer  -= 1
        next
      when "bracked_queries"
#        logger.debug ("#{ t[0] } : #{ query[ t[1]...t[2] ] }  --- #{t[1]} ... #{t[2]}")
        next
      when "query"
        selectedtokens = tokens.select { |to| ( tokens_begin <= to[1] &&  to[2]  <=  tokens_end ) }

#        logger.debug ("EsQueryGenerator  query - qtokens #{selectedtokens}")
#        logger.debug ("EsQueryGenerator  query - #{query}")

        query_string = create_query_string( selectedtokens,  query )

#        logger.debug ( "EsQueryGenerator  query => query_string #{query_string}" )
#        logger.debug ( "EsQueryGenerator  query => query_string.to_pretty_json \n#{query_string.to_pretty_json}" )
        
        queries << query_string

        next

      when "query_operator"
        prev_operator = operator
        prev_booleanType = booleanType

        operator = query.byte_slice( t[1], t[2]-t[1] )
        case operator
        when "OR"
          #should_array << query_string
          booleanType = "should"
        when "AND"
          #must_array << query_string
          booleanType = "must"
        when "AND NOT"
          booleanType = "mustnot"
          #mustnot_array << query_string 
        end

        if booleanType != prev_booleanType && prev_booleanType != ""
          logger.debug ( "EsQueryGenerator Not the same booleanType   booleanType [#{booleanType}] != prev_booleanType [#{prev_booleanType}] !!!!" )
          result = create_bool(queries, prev_booleanType)
          queries = [] of QueryCompound
          queries << result
        end

      when "query_index"
#        logger.debug ("#{ t[0] } : #{ query.byte_slice( t[1], t[2]-t[1] ) }  --- #{t[1]} ... #{t[2]}")
      when "query_terms"
#        logger.debug ("#{ t[0] } : #{ query.byte_slice( t[1], t[2]-t[1] ) }  --- #{t[1]} ... #{t[2]}")
      when "terms_operator"
#        logger.debug ("#{ t[0] } : #{ query.byte_slice( t[1], t[2]-t[1] ) }  --- #{t[1]} ... #{t[2]}")
      when "space"
        next
#        logger.debug ("#{ t[0] } : #{ query.byte_slice( t[1], t[2]-t[1] ) }  --- #{t[1]} ... #{t[2]}")
      else
#        logger.debug ("#{ t[0] } : #{ query.byte_slice( t[1], t[2]-t[1] ) }  --- #{t[1]} ... #{t[2]}")
      end
    end

    logger.debug ( "EsQueryGenerator end queries : #{queries }" )
    logger.debug ( "EsQueryGenerator end queries.size : #{queries.size }" )
    
    result = create_bool(queries, booleanType)   
    
    result

  end

  def self.create_bool(queries, booleanType)
    if queries.size == 1 && queries[0].has_key?("bool")
        return queries[0]
    end
    case booleanType
    when "should"
      bool_query = { :should => queries}
    when "must"
      bool_query = { :must => queries}
    when "mustnot"
      bool_query = { :mustnot => queries}
    else
      bool_query = { :must => queries}
    end 
    { :bool => bool_query }
  end

  def self.create_query_string(tokens, q)
    query = ""
    fields = "any"

    if  tokens[0][0].to_s ==  "query"
      tokens.shift
    end
    
    # query_terms can have multiple parts that also contains query_terms
    term_end = 0


    tokens.each_with_index do |t, i|
      case t[0].to_s 
      when "query_index"
        #fields = q[ t[1]...t[2] ]
        fields = q.byte_slice( t[1], t[2]-t[1] )
      when "query_terms"
        if term_end < t[2]
          #query += q[ t[1]...t[2] ]
          query += q.byte_slice( t[1], t[2]-t[1] )
          term_end = t[2]
        end
      when "terms_operator"
        if term_end < t[2]
          #query += " " +q[ t[1]...t[2] ]+ " "
          query += " " +q.byte_slice( t[1], t[2]-t[1] )+ " "
        end
      else
      #  puts "#{ addspace(10) }  ==> #{ t[0] } : #{ q[ t[1]...t[2] ] }  --- #{t[1]} ... #{t[2]}"
      end
    end
    #{ query_string:  { fields: fields, query: query.strip } }
    { :query_string =>  { :fields => [fields], :query => query.strip } }
  end


  def self.post_processing(bool_query, index_map, query_replacements)
      if bool_query.is_a?(Array)
        #LOGGER.debug ("EsQueryGenerator post_processing  bool_query Array")
        bool_query.map! do |el|
          #LOGGER.debug (el)
          #LOGGER.debug ( query_replacements.map { |qr| qr["source"].to_s } )

          qr_source = query_replacements.map { |qr| qr["source"].to_s.downcase  }

          LOGGER.debug(" el.to_s.downcase  #{ el.to_s.downcase }")
          if qr_source.includes?(el.to_s.downcase)
            qr_hash =  query_replacements.select{ |qr| qr["source"].to_s.downcase ==  el.to_s.downcase }
            if qr_hash.size > 1
              LOGGER.error("Multiple configurations for Source #{el.to_s}")
            end
            qr_hash = qr_hash[0]

            case qr_hash["type"]
            when "exists"
              qr_target = Hash(String, Hash(String, String)).from_json(qr_hash["target"].to_s)
              qr_target = { :exists => { :field => qr_target["exists"]["field"] } }.as(EsExistsString)
            when "query_string"
              LOGGER.debug("  qr_hash Source #{qr_hash["target"]}")
              qr_target = Hash(String, Hash(String, String | Array(String))).from_json(qr_hash["target"].to_s)
              qr_target = { :query_string => { :fields => qr_target["query_string"]["fields"], :query => qr_target["query_string"]["query"] }}.as(QueryCompound)
            else
              qr_target = el
            end

            LOGGER.debug ("EsQueryGenerator post_processing query_replacements type: #{ qr_hash["type"] }")          
            LOGGER.debug ("EsQueryGenerator post_processing replace: #{el.to_s}  ")
            LOGGER.debug ("EsQueryGenerator post_processing with   : #{ qr_target }")

            qr_target
            
          else
            post_processing( el, index_map, query_replacements).as(QueryCompound)
          end
        end
      end
      
      if bool_query.is_a?(Hash)
        #LOGGER.debug ("EsQueryGenerator post_processing  bool_query HASH")
        #LOGGER.debug (bool_query.keys)
        bool_query.each_key do |key|
          case key
          when :fields
            index = ( bool_query[:fields][0] ).to_s.downcase.rstrip(":") || "any"
            #LOGGER.debug ("bool_query HASH FIELDS:")
            #LOGGER.debug ( bool_query.class )
            if bool_query.is_a?( Hash(Symbol, Array(String) | String) )
              unless index_map.has_key?(index)
                bool_query[:fields] = index_map[ "any" ]
              else
                bool_query[:fields] = index_map[ index ]
              end
            end
          when :query
            if bool_query.is_a?( Hash(Symbol, Array(String) | String) )
              if bool_query[:query].is_a?(Array(String))
                bool_query[:query].as(Array).map do |q|
                  q = q.gsub(/(REIRES_[^ \)]*)/, "\"\\1\"")
                  q
                end
              end
              if bool_query[:query].is_a?(String)
                q = bool_query[:query]
                bool_query[:query] = q.as(String).gsub(/(REIRES_[^ \)]*)/, "\"\\1\"")
              end
            end
          else
            #LOGGER.debug ( typeof(bool_query) )
            #LOGGER.debug ( bool_query.class )
            if bool_query.is_a?( Hash(Symbol, Hash(Symbol, Array(EsQueryGenerator::QueryCompound))) )
              bool_query[key] = post_processing( bool_query[key], index_map, query_replacements)
            end
            if bool_query.is_a?(  Hash(Symbol, Array(EsQueryGenerator::QueryCompound)) )
              bool_query[key] = post_processing( bool_query[key], index_map, query_replacements)
            end
            if bool_query.is_a?( Hash(Symbol, Hash(Symbol, Array(String) | String)) )
              bool_query[key] = post_processing( bool_query[key], index_map, query_replacements)
            end
          
          end
        end
      end
      bool_query
  end

  def self.map_index_fields(bool_query,index_map)
    if bool_query.is_a?(Array)
      bool_query.each do |el|
          if el.is_a?( Hash(Symbol, Hash(Symbol, String | Array(String)) ))
            index = ( el[:query_string][:fields][0] ).to_s.downcase.rstrip(":") || "any"
            unless index_map.has_key?(index)
              el[:query_string][:fields] = index_map[ "any" ]
            else
              el[:query_string][:fields] = index_map[ index ]
            end
            if el[:query_string][:query].is_a?(Array(String))
              el[:query_string][:query].as(Array).map do |q|
                q = q.gsub(/(REIRES_[^ \)]*)/, "\"\\1\"")
                q
              end
            end
            if el[:query_string][:query].is_a?(String)
              q = el[:query_string][:query]
              el[:query_string][:query] = q.as(String).gsub(/(REIRES_[^ \)]*)/, "\"\\1\"")
            end
          else
            map_index_fields( el, index_map)
          end
      end
    end

    if bool_query.is_a?(Hash)
      if bool_query.has_key?(:bool) 
        bool_query[:bool].each_key do |key|
          if bool_query[:bool][key].is_a?(Array)
            bool_query = { :bool => { key => map_index_fields( bool_query[:bool][key] , index_map) } }
          else
            LOGGER.debug ("Not an Array bool_query[:bool][key]")
          end
        end
      end
    end
    bool_query
  end

end
