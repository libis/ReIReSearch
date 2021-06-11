require "./generic_parser"
require "./lucene_parser"
require "./../../search_blender/config"
require "./../../search_blender/helpers/*"


module Query
  class Parser

    def parse(query,engine)

      case engine
      when "brepols"
        q= Query::BrepolsParser.new
        q.parse(query)
      when "elastic"
        q = Query::ReIReSElasticParser.new
        q.parse(query)
      else
        q = Query::GenericParser.new
        q.parse(query)
      end
  
    end

  end
end
