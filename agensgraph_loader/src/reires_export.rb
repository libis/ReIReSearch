require 'net/http'
require 'uri'
require 'json'
require 'etc'
require './lib/Validator'
require './lib/agensgraph'
require './lib/PropertyContent'
require './lib/Exporter'
require 'fileutils'

host = 'agensgraph'
username = 'agens'
password = 'agens'
graph = 'reires_graph'

def removesubfolder(data)
  data.each do |key, value|
    if (value.kind_of?(Hash) && value['@subfolder'] != nil)
      removesubfolder(value) unless value.kind_of?(String) 
      data[key].delete('@subfolder') unless data[key] == nil
    end
    if (value.kind_of?(Array))
      value.each_with_index do |val, idx|
        data[key][idx].delete('@subfolder') unless  data[key][idx] == nil
        removesubfolder(val) unless val.kind_of?(String)
      end
    end
  end
  data.delete('@subfolder');
  data
end


starttime = Time.now
@agens = AgensGraph.new(host)
@agens.connect(username, password)
@agens.set_graph(graph)
@validator = Validator.new

puts ARGV


if (ARGV[0] == "" || ARGV[0].nil? || ARGV[1] == "" || ARGV[1].nil? )
  puts "Invalid parameters"
  exit
else
  folder = ARGV[0]
  folder.sub!("../datain/","")
  reqtype = ARGV[1]
  query = "MATCH (c:" + reqtype + ") WHERE c.'@subfolder' STARTS WITH '" + folder + "' return c.'@type' as at_type,c.'@id' as at_id, c.'additionalType' as additionaltype"
  puts query
end



list = @agens.execute_query(query)

NUM_THREADS =  (Etc.nprocessors() * 0.9).floor()  

Thread.abort_on_exception = true


@queue = Queue.new
list.each do |props|
  @queue.push(props);
end



@threads = Array.new(NUM_THREADS) do
  Thread.new do
    exporter = Exporter.new(host, username, password, graph)
    until @queue.empty?
      props = @queue.shift
#      puts props.at_type.value + " " + props.at_id.value
      struct = exporter.export(props.at_type.value, props.additionaltype.value, props.at_id.value)
#      pp struct

      subfolder = struct["@subfolder"].chomp("/")
      struct.delete("@importdatetimestamp")
      struct.delete("@maindocument")
      struct = removesubfolder(struct)

      json = struct.to_json
      outputfolder = "/app/dataout/" + subfolder
      begin
        FileUtils.mkdir_p(outputfolder) unless Dir.exist?(outputfolder)
      rescue
      end
      outputfilename = outputfolder + '/' + props.at_id.value.gsub(':','-') + '_' + props.at_type.value.upcase  + '.json'
      puts @queue.length().to_s + " Writing " + outputfilename
      File.write(outputfilename, json)

    end
  end
end
@threads.each(&:join)
stoptime = Time.now
puts "%10.9f" % (stoptime - starttime)
