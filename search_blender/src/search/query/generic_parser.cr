require "./lucene_grammar"

def underscore(camel_cased_word)
  word = camel_cased_word

  while (i = (/[A-Z]/ =~ word))
    b = word[0...i.to_i]
    s = i > 0 ? "_" : ""
    m = word[i].downcase
    e = word[i + 1..word.size]
    word = "#{b}#{s}#{m}#{e}"
  end
  word
end

module Query
  class GenericParser

    
    def initialize
        @open_bracket = 0
        @close_bracket = 0
        @logger = Logger.new(STDOUT)
        @logger = searchblender_logger()
    end


    enum MatchType
      Contains
      BeginsWith
      Exact
    end

    enum TermType
      Term
      Operator
    end

    struct Term
      property type : TermType
      property value : String
      property brackets : Bracket

      def initialize(@type : TermType, @value : String, @brackets : Bracket)
      end

      def to_s
        "#{@brackets.open}#{@value}#{@brackets.close}"
      end
    end

    struct Query
        property index : Array(String) | String
        property match : MatchType
        property terms : Array(Term)
    
        def initialize(@index : Array(String) | String, @match : MatchType, @terms : Array(Term))
        end
    
        def to_s
          terms_s = ""
          @terms.each do |term|
            if @terms.last == term && term.type == TermType::Operator
              terms_s += "," if terms_s.size > 0
            else
              terms_s += " " if terms_s.size > 0
            end
    
            terms_s += term.to_s
          end
    
          "#{@index},#{underscore(@match.to_s)},#{terms_s.rchop(" ")}"
        end
      end

    struct Bracket
        property open : String
        property close : String
  
        def initialize(@open = "", @close = "")
        end
    end

    def parse(q)
      
       begin
          #####################################################################
          # create QueryBlocks that consist of qeuries. 
          # These queries (one query per index) can contains brackets and boolean operators
          # The operators: 'OR' 'AND' and 'AND NOT'
          # Terms are treated as phrases as they are surrounded by double quotes
          # A term starting with an ^ means the match type will be start with.
          # The QueryBlocks themself can also be interconnected with boolean operator
		      #  ??????? EBNF gramar parser ???????
          #######################################################################
      
          brackets_count = 0 # count overall brackets (creating Query_blocks). At the end it has to be 0
          index_brackets = 0 # count brackets per index. At the end it has to be 0
      
          tokens = tokenize(q)
      
          queries =  [] of Query
          queryblock = [] of Array(Query) | Term
          parsed_query = Query.new(index: "", match: MatchType::Contains, terms: [] of Term)
      
          tokens.each do |token|

            brackets, token = extract_brackets_from_token(token)
           #puts  ( "token  #{token}" )
            @logger.debug ( "token  #{token}" )
            @logger.debug ( "brackets : #{brackets}" )

            if is_index?(token)
              @logger.debug ( "is_index : #{token}" )
            #  puts  ( "is_index : #{token}" )
                # If the index_backets are not 0 when starting a new index
                #  there is something wrong in the query
    
                # If the first trem of the current parser_query is a operator
                #  this operator will become the operator between the QueryBlocks
    
                # If the index is prefixed with a bracket 
                #  and the last trem of the current parser_query is a operator, 
                #  this operator will become the operator between the QueryBlocks

                if index_brackets == 0
                    unless parsed_query.terms.empty?
                        ## create a new QueryBlock with an operator
                        if parsed_query.terms[0].@type == TermType::Operator
                            queryblock.push( parsed_query.terms[0] )
                            parsed_query.terms.shift
                        end
                    end
                    unless parsed_query.terms.empty?
                      if parsed_query.index == ""
                        parsed_query.index = @index_map["any"]
                      end
                      queries << cleanup_query(parsed_query) unless parsed_query.terms.empty?
                    end
                else
                    raise " query error  Brackets do not match ( index_brackets #{index_brackets } )"
                end
    
                if  brackets.@open.size > 0
                    brackets_count += brackets.@open.size

                    unless queries.empty?
                        if queries.last.terms.last.@type == TermType::Operator
                            blockOperator = queries.last.terms.last
                            queries.last.terms.pop
                        end
                        queryblock.push(queries)  unless queries.empty?
                        queryblock.push(blockOperator) unless blockOperator.nil?
                    end
                    queries = [] of Query
                end
    
                parsed_query = Query.new(index: "", match: MatchType::Contains, terms: [] of Term)

                parsed_query.index = @index_map[token.rchop.downcase]
    
            elsif is_operator?(token)
              @logger.debug ( "is_operator : #{token}" )
                if brackets.@open.size > 0 || brackets.@close.size > 0
                    puts "OPERATOR CONTAINS BRACKETS ??????????"
                end
                # If the previous token was also an opetaror it is probably AND NOT and it should be combined in 1 Term
                unless parsed_query.terms.empty? 
                    last_term = parsed_query.terms.last
                    if last_term.@type == TermType::Operator
                        parsed_query.terms[-1] = Term.new(TermType::Operator, "#{last_term.@value} #{token}" , Bracket.new("", ""))
                    else
                        parsed_query.terms << Term.new(TermType::Operator, token, Bracket.new("", ""))
                    end
                else
                    parsed_query.terms << Term.new(TermType::Operator, token, Bracket.new("", ""))
                end
                
            elsif is_term?(token)
              @logger.debug ( "is_term: [#{token}]" )

                unless token.empty?
                  if token[0] == '^'
                    parsed_query.match = MatchType::BeginsWith
                    token = token[1..-1]
                  end
                end
                # Open brackets will increase the index_brackets
                # Close brackets will decrease the index_brackets
                # index_brackets must be 0 before a new index can be parsed
    
                # If the index_brackets become negative the close_brackets are
                # part of the QueryBlock structure 
                # the difference (negative index_brackets ) will be added to 
                # the 'overall' brackets_count
                # open overall brackets are part of the index-processing
                
                # example of a complex query :
                #  index1_1: trem1_1 OR (index2_1:term_2_1_1 term_2_1_2  AND index2_2:(term_2_2_1 OR term_2_2_2)) 
                #    AND NOT (index3_1:term_3_1_1 AND index3_2:term_3_2_1) OR index4_1:^term_4_1_1 AND index4_2:term_4_2_1


                index_brackets += brackets.@open.size
                index_brackets -= brackets.@close.size

                @logger.debug ( "index_brackets : #{index_brackets}" )
    
                parsed_query.terms << Term.new(TermType::Term, token, brackets)
    
                if index_brackets < 0
                    brackets_count += index_brackets
                    last_term = parsed_query.terms.last
                    brackets = Bracket.new(last_term.@brackets.@open, last_term.@brackets.@close[0...index_brackets])
                    parsed_query.terms[-1] = Term.new(last_term.@type, last_term.@value, brackets)
                    # TODO extra check if next token is an operator if not create the operator AND between the QueryBlocks
                    queries << cleanup_query(parsed_query) unless parsed_query.terms.empty?
                    queryblock.push(queries)  unless queries.empty?
                    parsed_query = Query.new(index: "", match: MatchType::Contains, terms: [] of Term)
                    queries = [] of Query
    
                    index_brackets = 0                
                end
            else
                puts "unknown #{token}"
            end
            if brackets_count < 0
                raise "query error  Brackets do not match ( brackets_count #{brackets_count } )"
            end
          end
          # add the last queries
          queries << cleanup_query(parsed_query) unless parsed_query.terms.empty?
          queryblock.push(queries)  unless queries.empty?
          queryblock

      rescue ex
          puts "ERROR PARSE #{ex.message}"
          queryblock = []  of Array(Query) | String
          queryblock
      end
    end
 
    private def tokenize(query : String) 
      begin
          # query = query.encode("UTF-8", invalid: :replace)
          query = query.gsub(/\b *?: *?/, ": ") # remove space between a word and :
          query = query.squeeze(" ") #remove all double spacings is the same as #query = query.gsub(/ {1,}/, " ")
  
          # check for qoutes and put qoutes string as 1 token
          qoute_size =  query.scan(/\"|\"/).size 
          if qoute_size.even? 
              if qoute_size > 0
                  q = query.partition( /"(?:[^"]+|(?R))*+"/) 
                  query = q[0].split(" ").reject &.empty?
                  query << q[1]
                  query.concat(tokenize(q[2])).reject &.empty?
              else
                  query = query.gsub(/([^(\s])\(/, "\\1 (") # put a space before ( unless it is an ( ==> OR((ANY:  will become OR ((ANY
                  query = query.gsub(/\)([^)\s])/, ") \\1") # put a space after ) unless it is an ) ==> ...))AND will become ...)) AND
                  query.split(" ").reject &.empty? #remove empty elements from the array
              end
          else
              raise "query error  Quotes do not match ( qoute_size #{qoute_size } )"
          end
      rescue ex
          puts "ERROR tokenize #{ex.message}"
          query = Array(String).new
          query
      end
    end

    private def is_index?(possible_index)
      return false if possible_index.nil?
      return false if possible_index.empty?
        if possible_index[-1] == ':'
          return @index_map.has_key?(possible_index.rchop.downcase)
        end
        return false
    end
    
    private def is_term?(possible_term)
        return false if possible_term.nil?
        return false if is_operator?(possible_term)

#        @open_bracket += possible_term.scan(/\(|\[|\"|\"/).size || 0
#        @close_bracket += possible_term.scan(/\)|\]|\"|\"/).size || 0
        return true
    end
  
    private def is_operator?(possible_operator)
        operators = %w(AND OR NOT)
        operators.includes?(possible_operator)
    end

    #private def cleanup_query_term(terms) forall T
    private def cleanup_query_term(terms = [] of Term)
        new_terms = [] of Term

        terms.each do |t|
            if t.type == TermType::Term
                term = t.value
                # remove dangling boolean operator
                unless (term.strip =~ /(AND|OR|NOT)$/).nil?
                    term = term.strip.gsub(/(AND|OR|NOT)$/, "").strip
                end
                # remove needles quotes
                #  term = term.gsub(/(^"|')|("|'$)/, "")
                term.strip
                t.value = term
                new_terms << t
            else
                new_terms << t
            end
        end
        new_terms
    end
  
    private def extract_brackets_from_token(token)
        brackets = Bracket.new((token.match(/(^\(*)/) || ["", ""])[1], (token.match(/(\)*$)/) || ["", ""])[1])
        token = token.gsub(/(^\(*)/, "").gsub(/(\)*$)/, "")
        return brackets, token
    end

    private def cleanup_query(parsed_query)
      if parsed_query.index == ""
        parsed_query.index = @index_map["any"]
      end
      parsed_query
    end

    private def collapse_if_exact_match(queries : Array(Query))
        new_queries = [] of Query
        queries.each do |query|
            if query.terms.first.value =~ /^["|']/ && query.terms.last.value =~ /["|']$/
                new_queries << Query.new(index: query.index,
                match: MatchType::Exact,
                terms: [Term.new(TermType::Term,
                            query.terms.map { |m| m.value }.join(" "),
                            Bracket.new("", ""))]
                )
            else
                new_queries << query
            end
        end
        new_queries
    end 

  end
end
