#################################################
# Global remark: Do not use ( or ) in the path
# unless it is for boolean operator
#################################################

module EnumerableExtensions
  def process_function_or_literal(exp, default = nil)
    return default if exp.nil? || exp.empty?
    return Integer(exp) if exp[0] != '('
    return nil unless @_current_node

    # Regex Lookahead and lookbehind assertions
    # /@? ( (?<!\d) \. (?!\d) (\w+) )+/
    # (?<!\d) ensures that the characters preceeding your expression do not match \d
    # (?!\d)  ensures that the characters following  your expression do not match \d
    #identifiers = /@?((?<!\d)\.(?!\d)(\w+))+/.match(exp)

    #LIBIS A method can also contains an ! or ?
    # example : '$.datafield[?(@["_tag"] == "700" ||  @["_tag"] == "710" )].subfield[?(@["4"].include? "edt")]'

    identifiers = /@?((?<!\d)\.(?!\d)(\w+\??!?))+/.match(exp)

    if !identifiers.nil? && !@_current_node.methods.include?(identifiers[2].to_sym)
      exp_to_eval = exp.dup
      exp_to_eval[identifiers[0]] = identifiers[0].split('.').map do |el|
        el == '@' ? '@' : "['#{el}']"
      end.join
      begin
        return JsonPath::Parser.new(@_current_node).parse(exp_to_eval)
      rescue StandardError
        return default
      end
    end
    JsonPath::Parser.new(@_current_node).parse(exp)
  end
end

module ParserExtensions
    # parse will parse an expression in the following way.
    # Split the expression up into an array of legs for && and || operators.
    # Parse this array into a map for which the keys are the parsed legs
    #  of the split. This map is then used to replace the expression with their
    # corresponding boolean or numeric value. This might look something like this:
    # ((false || false) && (false || true))
    #  Once this string is assembled... we proceed to evaluate from left to right.
    #  The above string is broken down like this:
    # (false && (false || true))
    # (false && true)
    #  false
    def parse(exp)
      exps = exp.split(/(&&)|(\|\|)/)
      construct_expression_map(exps)
      @_expr_map.each { |k, v| exp.sub!(k, v.to_s) }
      raise ArgumentError, "unmatched parenthesis in expression: #{exp}" unless check_parenthesis_count(exp)
     
      # LIBIS begin
      # exp can have spaces
      exp.strip!
      # LIBIS end

      exp = parse_parentheses(exp) while exp.include?('(')
      bool_or_exp(exp)

    end

    # Using a scanner break down the individual expressions and determine if
    # there is a match in the JSON for it or not.
    def parse_exp(exp)
      #puts " exp  #{ exp } "
      # LIBIS ADD - Begin
      # use !@ for negations
      negations = /^!/.match(exp)
      exp = exp.sub(/^!/, '')
      # LIBIS ADD - End

      exp = exp.sub(/@/, '').gsub(/^\(/, '').gsub(/\)$/, '').tr('"', '\'').strip
      exp.scan(/^\[(\d+)\]/) do |i|
        next if i.empty?
        index = Integer(i[0])
        raise ArgumentError, 'Node does not appear to be an array.' unless @_current_node.is_a?(Array)
        raise ArgumentError, "Index out of bounds for nested array. Index: #{index}" if @_current_node.size < index
        @_current_node = @_current_node[index]
        # Remove the extra '' and the index.
        exp = exp.gsub(/^\[\d+\]|\[''\]/, '')
      end

      scanner = StringScanner.new(exp)
    
      elements = []

      until scanner.eos?
        # LIBIS customizations :
        # example : ["4"].include? "edt" => 4 must be detected
        if (t = scanner.scan(/\['[a-zA-Z0-9@&*\/$%^?_]+'\]\.[a-zA-Z0-9_]+[?!]?/))
          if (t.match /\.[a-zA-Z0-9_]+\?$/)
            operator = t.split('.').last
            elems = t.split('.')[0...-1].join('.')
            t = elems
          end
          elements << t.gsub(/[\[\]'.]|\s+/, '')
        #if (t = scanner.scan(/\['[a-zA-Z@&*\/$%^?_]+'\]|\.[a-zA-Z0-9_]+[?!]?/))
        elsif (t = scanner.scan(/\['[a-zA-Z0-9@&*\/$%^?_]+'\]|\.[a-zA-Z0-9_]+[?!]?/))
          elements << t.gsub(/[\[\]'.]|\s+/, '')
        elsif (t = scanner.scan(/(\s+)?[<>=!\-+][=~]?(\s+)?/))
          operator = t
        elsif (t = scanner.scan(/(\s+)?'?.*'?(\s+)?/))
          # If we encounter a node which does not contain `'` it means
          #  that we are dealing with a boolean type.
          operand = if t == 'true'
                      true
                    elsif t == 'false'
                      false
                    else
#                      operator.to_s.strip == '=~' ? t.to_regexp : t.gsub(%r{^'|'$}, '').strip
                      operator.to_s.strip == '=~' ? t.to_regexp : t.strip.gsub(%r{^'|'$}, '').strip
                    end
        elsif (t = scanner.scan(/\/\w+\//))
#puts " ???????? #{t}"                    
        elsif (t = scanner.scan(/.*/))
          raise "Could not process symbol: #{t}"
        end
      end

      #puts "elements #{elements} "

      el = if elements.empty?
        @_current_node
      elsif @_current_node.is_a?(Hash)
        @_current_node.dig(*elements)
      else
        elements.inject(@_current_node, &:__send__)
      end

      #puts "el.nil?  #{el.nil? } "
      #puts "  negations  #{ negations } "

      return (el ? "#{negations}true" : "#{negations}false") if el.nil? || operator.nil?

      el = Float(el) rescue el
      operand = Float(operand) rescue operand

      #puts "el.__send__(operator.strip, operand) "
      #puts "#{el} send (#{operator.strip}, #{operand}) "


      el.__send__(operator.strip, operand) rescue false
    end





    #  This is convoluted and I should probably refactor it somehow.
    #  The map that is created will contain strings since essentially I'm
    # constructing a string like `true || true && false`.
    # With eval the need for this would disappear but never the less, here
    #  it is. The fact is that the results can be either boolean, or a number
    # in case there is only indexing happening like give me the 3rd item... or
    # it also can be nil in case of regexes or things that aren't found.
    # Hence, I have to be clever here to see what kind of variable I need to
    # provide back.
    def bool_or_exp(b)
      if b.to_s == 'true'
        return true
      #LIBIS        
      # Added negations
      elsif b.to_s == 'false'
        return false
      elsif b.to_s == '!true'
          return false
      elsif b.to_s == '!false'
          return true
      elsif b.to_s == ''
        return nil
      end

      b = Float(b) rescue b
      b
    end



    # This will break down a parenthesis from the left to the right
    # and replace the given expression with it's returned value.
    # It does this in order to make it easy to eliminate groups
    # one-by-one.
    def parse_parentheses(str)
      opening_index = 0
      closing_index = 0

      (0..str.length - 1).step(1) do |i|
        opening_index = i if str[i] == '('
        if str[i] == ')'
          closing_index = i
          break
        end
      end

      to_parse = str[opening_index + 1..closing_index - 1]

      #  handle cases like (true && true || false && true) in
      # one giant parenthesis.
      top = to_parse.split(/(&&)|(\|\|)/)
      top = top.map(&:strip)
      res = bool_or_exp(top.shift)
      top.each_with_index do |item, index|
        case item
        when '&&'
          # LIBIS change 1 line
          # res &&= top[index + 1]
          res &&= bool_or_exp( top[index + 1] )
        when '||'
          # LIBIS change 1 line
          # res ||= top[index + 1]
          res ||= bool_or_exp( top[index + 1] )
        end
      end
      #  if we are at the last item, the opening index will be 0
      # and the closing index will be the last index. To avoid
      # off-by-one errors we simply return the result at that point.
      if closing_index + 1 >= str.length && opening_index == 0
        return res.to_s
      else
        return "#{str[0..opening_index - 1]}#{res}#{str[closing_index + 1..str.length]}"
      end
    end

end

class JsonPath
  class Parser
       prepend ParserExtensions
  end
end

class JsonPath
  class Enumerable
      prepend EnumerableExtensions
  end
end

