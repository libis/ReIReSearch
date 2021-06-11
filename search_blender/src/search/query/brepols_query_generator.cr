
module BrepolsQueryGenerator
    VERSION = "0.1.0"
    LOGGER = searchblender_logger()
    
    def self.build_query( tokens : Array( Pegmatite::Token  ) , query : String, index_map, query_replacements = Array( Hash(String, String)).new )
      begin
        LOGGER.debug ( "BrepolsQueryGenerator: query #{ query }" )
        query = EsQueryGenerator.create_query( tokens,  query )

        LOGGER.debug ( "BrepolsQueryGenerator: start post_processing" )
        query = EsQueryGenerator.post_processing(query, index_map, query_replacements)

        LOGGER.debug ( "BrepolsQueryGenerator: query #{ query }" )
        format_query( query,  index_map  ) # return queryinput for Brepols
      rescue ex
        LOGGER.error "ERROR BrepolsQueryGenerator build_query #{ex.message}"
        return ""
      end
    end

    def self.build_filter( tokens : Array( Pegmatite::Token  ) , query : String, index_map, query_replacements = Array( Hash(String, String)).new )
      begin
        LOGGER.debug ( "BrepolsQueryGenerator: query #{ query }" )
        query = EsQueryGenerator.create_query( tokens,  query )

        LOGGER.debug ( "BrepolsQueryGenerator: start post_processing" )
        query = EsQueryGenerator.post_processing(query, index_map, query_replacements)

        LOGGER.debug ( "BrepolsQueryGenerator: query #{ query }" )
        format_filter( query,  index_map  ) # return queryinput for Brepols

      rescue ex
        LOGGER.error "ERROR BrepolsQueryGenerator build_filter #{ex.message}"
        filter = [{ "FilterField": "index", "FilterValue": "terms" }]
        filter.clear
        return { query: "" , filter: filter }
      end
    end

    def self.build_sort ( sort, sort_map )
      begin
        if sort_map.has_key?(sort)
          sort_index =  sort_map[sort]["index"].to_s
          sort_order =  sort_map[sort]["order"].to_s.upcase
          r_sort = "#{sort_index} #{sort_order}"
          unless sort == "relevance"
            relevance_index =  sort_map["relevance"]["index"].to_s
            relevance_order =  sort_map["relevance"]["order"].to_s.upcase
            r_sort = "#{r_sort}, #{relevance_index} #{relevance_order}"
          end
        end
        return r_sort
      rescue ex
        LOGGER.error "ERROR BrepolsQueryGenerator build_sort #{ex.message}"
        return nil
      end 
    end

    def self.format_query(bool_query, index_map)

      logger = Logger.new(STDOUT)
      logger = searchblender_logger()
    
      r_query=""
      logger.debug ("BrepolsQueryGenerator: bool_query #{ bool_query} \n")
    
      if bool_query.has_key?(:bool)
        logger.info ("BrepolsQueryGenerator: bool_query.has_key?(bool) #{ bool_query[:bool].to_h.keys } \n")
        bool_query.to_h[:bool].each do |bool, queries|
    
          logger.debug ("BrepolsQueryGenerator: bool: #{ bool } \n")
          logger.debug ("BrepolsQueryGenerator: queries: #{ queries } \n")
          logger.debug ("BrepolsQueryGenerator: #{ queries.size }")
    
          case bool
          when :must
            operator = "AND"
          when :should
            operator = "OR"
          when :mustnot
            operator = "AND NOT"
          else
            operator = "unknown"
            logger.error ("BrepolsQueryGenerator:  bool unknown !!!! #{bool} \n")
          end
          
          if queries.is_a?(Array)
            r_query_part=""
            queries.each do | query |
              logger.debug ( "BrepolsQueryGenerator: query: #{query} ")
              r_query_part = "#{r_query_part} #{operator} " unless r_query_part.empty?
              unless query.is_a?(String)
                if query.has_key?(:bool)
                  r_query_part = "#{ r_query_part }#{ (format_query(query, index_map)).to_s }"
                end
            
                if query.has_key?(:query_string)
                  logger.debug ( "BrepolsQueryGenerator query: #{ query.to_h[:query_string] } ")
                  querystring = query.to_h[:query_string]
                  index = querystring.to_h[:fields][0]
      
                  # Mapping to the correct index is already done during EsQueryGenerator.post_processing
                  # if index_map.has_key?(index)
                  #  index = index_map[index][0] || "any"
                  # else
                  #  index = "any"
                  # end

                  # Index on provider is not available in Brepols
                  # The provider is always Brepols
                  terms = querystring.to_h[:query]
                  case index.to_s 
                  when "provider"
                    r_query_part = r_query_part + parse_provider(terms)
                  when "dataset"
                    r_query_part = r_query_part + parse_dataset(terms)
                  else
                    r_query_part = r_query_part + index.to_s + ":" + terms.to_s
                  end
                  
                end
              end
              r_query_part = r_query_part.strip
            end
            r_query = r_query_part
          else
            r_query = queries
          end
    
          if ( queries.size > 1)
            r_query = "(#{r_query })"
          end
    
        end 
      end
      logger.debug ( "BrepolsQueryGenerator r_query #{ r_query } ")

      r_query = r_query.gsub(/ (AND|OR|AND NOT)\)$/, ")") 

      r_query.strip
    end


    def self.format_filter(bool_query, index_map)
      ################################################
      # BREPOLS FILTER:
      # Posible filter fields:
      #   “author”, “subject”, “type”, “language”, “publisher”, “publicationdate”.
      #
      # JSON-format of the request:
      # "Filters":[
      #  {
      #        "FilterField":"publisher",
      #        "FilterValue":"Brepols"
      #  },
      #  {
      #        "FilterField":"language",
      #        "FilterValue":"nl"
      #  },      
      #  {
      #        "FilterField":"publicationdate",
      #        "FilterValue":"2004"
      #  }
      # ]
      #
      # Multiple value of the same filterfield can be made by publication the object:
      # "Filters":[
      #  {
      #        "FilterField":"language",
      #        "FilterValue":"fr"
      #  },
      #  {
      #        "FilterField":"language",
      #        "FilterValue":"nl"
      #  },      
      # ]
      #
      # Filter on range is not possible
      # publicationdate:[1980 TO 2004] must be transformed to searchquery not filter
      # 
      ################################################

      LOGGER.debug ("BrepolsQueryGenerator format_filter: bool_query #{ bool_query}")
      begin
  
        r_query = String.new
        r_filter = [{ "FilterField": "index", "FilterValue": "terms" }] 
        r_filter.clear
  
        if bool_query.has_key?(:bool)
          LOGGER.info ("BrepolsQueryGenerator format_filter: bool_query.has_key?(bool) #{ bool_query[:bool].to_h.keys } \n")
          
          bool_query.to_h[:bool].each do |bool, queries|
            LOGGER.debug ("BrepolsQueryGenerator format_filter: bool: #{ bool } \n")
            LOGGER.debug ("BrepolsQueryGenerator format_filter: queries: #{ queries } \n")
            LOGGER.debug ("BrepolsQueryGenerator format_filter: #{ queries.size }")
  
            case bool
              when :must
                operator = "AND"
              when :should
                operator = "OR"
              when :mustnot
                operator = "AND NOT"
              else
                operator = "unknown"
                LOGGER.error ("BrepolsQueryGenerator: format_filter bool unknown !!!! #{bool} \n")
            end
            
            if queries.is_a?(Array)
              r_query_part=""
              queries.each do | query |
                LOGGER.debug ( "BrepolsQueryGenerator format_filter: query: #{query} ")
                
                unless query.is_a?(String)
                  if query.has_key?(:bool)
                    LOGGER.debug ( "BrepolsQueryGenerator format_filter sub_bool_query: #{ query} ")
                    ff = format_filter( query,  index_map  )
                    LOGGER.debug ( "BrepolsQueryGenerator format_filter ff: #{ ff } ")
                    LOGGER.debug ( "BrepolsQueryGenerator format_filter fffilter: #{ ff[:filter] } ")
                    unless ff[:filter].nil?
                      if ff_c = ff[:filter]
                        r_filter.concat( ff_c )
                      end
                    end
                    r_query_part = "#{r_query_part} #{operator}" unless r_query_part.empty?
                    r_query_part = "#{r_query_part} #{( ff[:query]).to_s }"
                  end
              
                  if query.has_key?(:query_string)
                    LOGGER.debug ( "BrepolsQueryGenerator format_filter: query.to_h[:query_string]: #{ query.to_h[:query_string] } ")
                    querystring = query.to_h[:query_string]
                    index = querystring.to_h[:fields][0].to_s.downcase
                    terms = querystring.to_h[:query]
  
                    # Mapping to the correct index is already done during EsQueryGenerator.post_processing
                    # if index_map.has_key?(index)
                    #  index = index_map[index][0] || "any"
                    # else
                    #  index = "any"
                    # end
  
                    # Fitlering on provider, dataset, publicationdate range is not availabel in Brepols
                    LOGGER.debug ( "BrepolsQueryGenerator format_filter: index: #{ index.to_s.downcase } ")
                      
                    case index.to_s.downcase
                    when "provider"
                      r_query_part = "#{r_query_part} #{operator} " unless r_query_part.empty?
                      r_query_part = r_query_part +  parse_provider(terms)
                    when "dataset"
                      r_query_part = "#{r_query_part} #{operator} " unless r_query_part.empty?
                      r_query_part = r_query_part +  parse_dataset(terms)
                    when "publicationdate"
                      r_query_part = "#{r_query_part} #{operator} " unless r_query_part.empty?
                      r_query_part = r_query_part + index.to_s + ":" + terms.to_s
                    when "language"
                      iso_639 = JSON.parse ( SearchBlender.config.read_json_config("iso639.json") )
                      iso_639_obj = iso_639.as_a.select{ |e| e.as_h.has_key?("alpha3-b") }
                      iso_obj =  iso_639_obj.select { |e| e["alpha3-b"] == terms.to_s.downcase.gsub("\"","")  }
                      LOGGER.debug ( "BrepolsQueryGenerator format_filter: iso_obj :#{iso_obj}")
                      #r_query_part = r_query_part + index.to_s + ":" + iso_obj[0]["alpha2"].to_s
                      r_filter << { "FilterField": index.to_s, "FilterValue":  iso_obj[0]["alpha2"].to_s }
                    else
                      #r_query_part = r_query_part + index.to_s + ":" + terms.to_s
                      r_filter << { "FilterField": index.to_s, "FilterValue":  terms.to_s.gsub("\"","") }
                    end
                    
#                    unless ["provider","dataset"].includes?(index.to_s.downcase)
#                      case index.to_s.downcase
#                      when "language"
#                        iso_639 = JSON.parse ( SearchBlender.config.read_json_config("iso639.json") )
#                        iso_639_obj = iso_639.as_a.select{ |e| e.as_h.has_key?("alpha3-b") }
#                        iso_obj =  iso_639_obj.select { |e| e["alpha3-b"] == terms.to_s.downcase.gsub("\"","")  }
#                        LOGGER.debug ( "BrepolsQueryGenerator format_filter: iso_obj :#{iso_obj}")
#                        r_query_part = r_query_part + index.to_s + ":" + iso_obj[0]["alpha2"].to_s
#                        r_filter << { "FilterField": index.to_s, "FilterValue":  iso_obj[0]["alpha2"].to_s }
#                      else
#                        r_query_part = r_query_part + index.to_s + ":" + terms.to_s
#                        r_filter << { "FilterField": index.to_s, "FilterValue":  terms.to_s.gsub("\"","") }
#                      end
#                    end

                  end
                end
                  r_query_part = r_query_part.strip
              end
              r_query = r_query_part
            else
              r_query = queries
            end
  
          end
        end

        r_query = r_query.gsub(/ (AND|OR|NOT)\)$/, ")") 

        return { "query": r_query ,  "filter": r_filter }
      rescue ex
        LOGGER.error "ERROR BrepolsQueryGenerator format_filter #{ex.message}"
        return { "query": r_query.to_s ,  "filter": r_filter }
      end
    end
    
    def self.parse_provider(terms)
      LOGGER.debug ( "BrepolsQueryGenerator: terms.to_s.downcase : #{terms.to_s.downcase} ")
      if ( Regex.new( "brepols" ).match(terms.to_s.downcase) && ! Regex.new(" AND ").match(terms.to_s) )
        #Don't add this to r_query_part. Brepols does not have an index on provider
        "any:BREPOLIS*"
      else
        "any: \"Index on provider is not yet supported\""
      end
    end

    def self.parse_dataset(terms)
      LOGGER.debug ( "BrepolsQueryGenerator: terms.to_s.downcase : #{terms.to_s.downcase} ")
      if ( Regex.new( "index religiosus" ).match(terms.to_s.downcase) && ! Regex.new(" AND ").match(terms.to_s) )
        #Don't add this to r_query_part. Brepols does not have an index on provider
        "any:BREPOLIS*"
      else
        "any: \"Index on dataset is not yet supported\""
      end 
    end
end  