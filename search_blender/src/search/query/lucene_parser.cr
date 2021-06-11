require "./generic_parser"
require "./lucene_grammar"

module Query
  class ReIReSLuceneParser < GenericParser

    def initialize
      super()
    end

    def parse(q : String, search_indexes = SearchBlender.config.search_indexes ) 
      begin
        grammar = LUCENEGrammar.new()
        @logger.debug ( "ReIReSLuceneParser parse q : #{q.to_s}" )
        @logger.debug ( "ReIReSLuceneParser parse search_indexes : #{search_indexes }" )

        tokens = Pegmatite.tokenize( grammar.grammar( search_indexes ), q.to_s)

     #   @logger.debug ( " Query - Results ... \n{\n query: \"#{ q }\",\n result: \n\"#{ tokens }\" \n}\n.. Query - Results END" )
        return tokens
      return
      rescue ex
        @logger.error "ERROR ReIReSLuceneParser parse #{ex.message}"
        return Array( Pegmatite::Token ).new
      end

    end
  end
end