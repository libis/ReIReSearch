require 'json'
require './lib/Validator'


@validator = Validator.new

def vlabel(type)
  c = @validator.info(type)
  line = "CREATE VLABEL " + type
  line += " INHERITS (" + c['inherits'] + ")" if !c['inherits'].is_a?NilClass
  line += ";"
  puts line
  line = "CREATE UNIQUE PROPERTY INDEX ON " + type + "(\"@id\");"
  puts line
  @validator.childrenOf(type).each do |v|
    vlabel(v)
  end
end

def elabel
  rels = []

  @validator.all_relations.sort.each do |r|
    puts "CREATE ELABEL " + r + ";"
  end

end

def drop_elabel
  rels = []

  @validator.all_relations.sort.each do |r|
    puts "DROP ELABEL " + r + ";"
  end

end


puts "CREATE GRAPH reires_graph;";
vlabel('Thing')
elabel

puts "      "
puts "      "
puts "      "

drop_elabel
puts "DROP VLABEL Thing CASCADE;"

