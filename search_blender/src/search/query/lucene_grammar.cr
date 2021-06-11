
require "pegmatite"

module Query
    class LUCENEGrammar
        def grammar(search_indexes = ["any"])            
            Pegmatite::DSL.define do
                # Forward-declare `array` and `object` to refer to them before defining them.
                query_terms  = declare
                queries_blok = declare

                # Define what optional whitespace looks like.
                s = ((char(' ') | char('\t') | char('\r') | char('\n')  ).repeat ).named(:space)
                # Define what a number looks like.

                digit19 = range('1', '9')
                digit = range('0', '9')
                digits = digit.repeat(1)
                int =
                (char('-') >> digit19 >> digits) |
                (char('-') >> digit) |
                (digit19 >> digits) |
                digit
                frac = char('.') >> digits
                exp = (char('e') | char('E')) >> (char('+') | char('-')).maybe >> digits
                number = (int >> frac.maybe >> exp.maybe).named(:number)
                hex = digit | range('a', 'f') | range('A', 'F')
                field_char = ( range('a', 'z') | range('A', 'Z') | char('_') )

                index_list = str("ANY")
                search_indexes.map { |si|
                        index_list = index_list | str("#{si}") | str("#{si.camelcase}") | str("#{si.camelcase(lower: true)}") | str("#{si.capitalize}") | str("#{si.downcase}") | str("#{si.upcase}")
                }

                #field = ( field_char.repeat >> char(':') ).named(:query_index)
                #index_field = ( ( str("any") | str("author") )>> char(':') ).named(:query_index)
                index_field = ( index_list ).named(:query_index) >> char(':')
            



                open_brackets =  ( char('[') | char('(') | char('{') | char(' ') )
                close_brackets = ( char(']') | char(')') | char(']') | char(' ') )

                or_operator  = ( str("OR") )
                and_operator = ( str("AND") )
                not_operator = ( str("AND NOT") )

                operators =  (not_operator | or_operator | and_operator )

                operators_between_terms = operators.named(:terms_operator) >> s >> ~( index_field | ( char('(') >> s >> index_field ))

                string_char = (~char('"') >> range(' ', 0x10FFFF_u32))

                brackets = char('[') | char(']') 
                range_char = ( ~brackets >> range(' ', 0x10FFFF_u32))
                
                quoted_term  = ( char('"') >> string_char.repeat >> char('"') ).named(:quoted_string)
                range_term = (char('[') >> range_char.repeat >> char(']') ).named(:range_string)
                
#                regular_term = ( ( ~( operators | index_field | char('(') | char(')') ) >> range(' ', 0x10FFFF_u32) ).repeat(1) ).named(:regular_string) 
                regular_term = ( ( ~( close_brackets >> operators >> open_brackets| index_field | char('(') | char(')') ) >> range(' ', 0x10FFFF_u32) ).repeat(1) ).named(:regular_string) 

                term = ( quoted_term | range_term | regular_term ).named(:term)

                #terms_values = term | query_terms 
                terms_values = ( ~( (close_brackets >> operators) | index_field | char('(') | char(')') )  >> term ) | ~( (close_brackets >> operators) | index_field  ) >> query_terms
                terms = ( terms_values >> (s >> operators_between_terms >> s >> terms_values ).repeat)
                
                terms_choice = ( (char('(') >> s >> terms >> s >> char(')')) | (s >> terms >> s ) ).named(:query_terms)
                query_terms.define ( terms_choice   >> ( s >>  operators_between_terms >> s >> terms_choice  ).repeat  ) 

                rest =  range(' ', 0x10FFFF_u32).repeat
                query = ( ( index_field ) >> s >> (query_terms) ).named(:query)
                
                query_values = query | queries_blok | rest
                queries = ( query_values >> (s >> operators.named(:query_operator)  >> s >> query_values ).repeat)

                #queries_blok_choice = ( regular_term.named(:query).named(:query_terms) | (char('(') >> s >> queries >> s >> char(')')) |  ( s >> queries >> s  ) ).named(:queries)
                queries_blok_choice = ( (s >> char('(') >> s >> queries >> s >> char(')') >> s).named(:bracked_queries) |  ( s >> queries >> s  ) ).named(:queries)
                queries_blok.define ( queries_blok_choice   >> ( s >> operators.named(:query_operator)  >> s >> queries_blok_choice  ).repeat  ) 
                (queries_blok).then_eof
            end
        end
    end
end
