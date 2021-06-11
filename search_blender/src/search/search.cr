require "logger"
require "./engines/elastic_search"
require "./engines/brepols_search"
require "./../search_blender/config"
require "./../search_blender/helpers/*"

module Search
  VERSION = "0.2.0"
  
  class Search

    
    def initialize(options = {} of String => String)

      @logger = Logger.new(STDOUT)
      @logger = searchblender_logger()

      @logger.debug ( "Search::Search : initialize - options")
      @logger.debug ( "  #{options}" )
      
      @search_engine = ElasticSearch.new

      case options["engine"]
      when "elastic"
        @search_engine = ElasticSearch.new
      when "brepols"
        @search_engine = BrepolsSearch.new        
      else
        @search_engine = ElasticSearch.new
      end
    end

    def query(q : String, f : String, options = {} of String => String)
      #@search_engine.query(q, options).to_json
      @logger.debug ( "Search::Search : query - @search_engine" )
      @logger.debug ( @search_engine )
      @logger.debug ( options )
      #q = "(description.@value:vons OR description.@value:van) OR (author.name.@value:ben)"

      q = starts_with_index(q) unless q.empty?

      @search_engine.query(q, f, options)
    end


    def record (id : String, options = {} of String => String)
      #id = REIRES_JGUMainz_JGUMAINZ_urn:nbn:de:hebis:77-vcol-12060
      @search_engine.record(id, options)
    end
    
     
    def starts_with_index (q : String , search_indexes = SearchBlender.config.search_indexes)
      index_regex = search_indexes.join("|")
      unless /^[(\s]*(#{index_regex}):/i.match( q )
        regex = /(.*?)(?=\s*(AND|OR|NOT|#{index_regex}:|$))/
        @logger.debug ( "starts_with_index :regex.match #{regex.match(q)}" )
        @logger.debug ( "starts_with_index q.sub(regex, nkrf) #{ q.sub(regex, "any:(\\1)") }" )
        return q.sub(regex, "any:(\\1)")
      end
      q
    end

  end

end
