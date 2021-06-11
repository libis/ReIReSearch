require 'net/http'
require 'uri'
require 'json'
require './lib/Validator'
require './lib/PropertyContent'
require './lib/agensgraph'
require './lib/Ingester'
require './lib/Exporter'

def generate_vlabel(type, validator, agens)
  c = validator.info(type)
  line = "CREATE VLABEL " + type
  line += " INHERITS (" + c['inherits'] + ")" if !c['inherits'].is_a?NilClass
  line += ";"
  puts line
  agens.execute(line)
  line = "CREATE UNIQUE PROPERTY INDEX ON " + type + "(\"@id\");"
  puts line
  agens.execute(line)
  validator.childrenOf(type).each do |v|
     generate_vlabel(v, validator, agens)
  end
end

def generate_elabel(validator,agens)
  rels = []
  validator.all_relations.sort.each do |r|
    line = "CREATE ELABEL " + r + ";"
    agens.execute(line)    
  end
end


def insertsubfolder(data, subfolder)
  data.each do |key, value|
    if (value.kind_of?(Hash) && value['@type'] != nil)
      data[key] = insertsubfolder(value, subfolder)
    end
    if (value.kind_of?(Array))
      value.each_with_index do |val, idx|
        data[key][idx] = insertsubfolder(val, subfolder) unless val['@type'] == nil
      end
    end
  end
  data["@subfolder"] = subfolder
  data
end


starttime = Time.now

ingester = Ingester.new('agensgraph','agens','agens', 'reires_graph')


baseurl = "https://reiresearch.eu/record/"
today = starttime.strftime("%Y-%m-%d")
sdPublisher = JSON.parse('{"@type":"Organization","@id":"ReIReS_consortium","name":"ReIReS consortium","location":"Europe"}')
sdLicense = "https://creativecommons.org/licenses/"

ingester.setStoredDataParameter("url",baseurl)
ingester.setStoredDataParameter("sdPublisher",sdPublisher)
ingester.setStoredDataParameter("sdDatePublished",today)
ingester.setStoredDataParameter("sdLicense",sdLicense)


validator = Validator.new

if (ARGV[0] == "clear")
  ingester.clearGraph
end

if (ARGV[0] == "load" && ARGV[1] != "")
  subfolder = ARGV[1]
  subfolder.sub!("../datain/","").chomp("/");
  datain = '/app/datain/' + subfolder

  puts "Reading datafiles " + datain
#  Dir.foreach(datain) do |filename|
  Dir.glob(datain + '*.json') do |filename|
#  ["/app/datain/DHGE/REIRES_Brepols_DHGE_BREPOLIS-BHRR-ARTL-v2p10_1607953165_798.json"].each do |filename|
    foo = StringIO.new
    $stdout = foo


    puts "Processing " + filename
    file = File.open(filename, 'r:utf-8')
    content = file.read
    data = JSON.parse(content)

    data["isBasedOn"]["isPartOf"]["url"] = "https://reiresearch.eu/page/about#" + data["isBasedOn"]["isPartOf"]["@id"] 

    if (validator.validate(data))

      data = insertsubfolder(data, subfolder)

      data["@maindocument"] = 1
      data["@importdatetimestamp"] = starttime.to_f
      ingester.ingest(data)
    else
      errfile = File.open(datain + '/' + filename + ".err", 'w')
      errfile.write($stdout.string)
      errfile.close
    end
    file.close
    STDOUT.puts $stdout.string
  end
end

if (ARGV[0] == "validate" && ARGV[1] != "")
  subfolder = ARGV[1]
  subfolder.sub!("../datain/","");
  datain = '/app/datain/' + subfolder

  puts "Reading datafiles " + datain
#  Dir.foreach(datain) do |filename|
  Dir.glob(datain + '*.json') do |filename|
    puts "Processing " + filename
    file = File.open(filename, 'r:utf-8')
    content = file.read
    data = JSON.parse(content)
    validator.validate(data)
  end
end

if (ARGV[0] == "create") 
  agens = AgensGraph.new('agensgraph')
  agens.connect('agens','agens')

  graph = ARGV[1]
  line = "CREATE GRAPH " + graph + ";"
  puts line
  agens.execute(line)
  agens.set_graph(graph)

  generate_vlabel('Thing',validator, agens)
  generate_elabel(validator, agens)
end


stoptime = Time.now
puts "%10.9f" % (stoptime - starttime)



