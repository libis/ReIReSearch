require 'uri'
require './lib/agensgraph'
require 'date'

class Ingester
  def initialize(host,username,password, graph)
    @agens = AgensGraph.new(host)
    @agens.connect(username, password)
    @agens.set_graph(graph)
    @validator = Validator.new
    @sdParameters = {}
  end

  def setStoredDataParameter(key, value) 
      @sdParameters[key] = value
  end

  def createNode(nodedata)
#    puts "createNode" + nodedata['@type']
#    puts nodedata
    query = 'MATCH (x:' + nodedata['@type'].downcase + "{'@id':'" + nodedata['@id'] + "'}) return count(*)"
#    puts query
    resp = @agens.execute_query(query)

    if resp[0].count.value == 0
#     puts "node aanmaken"
      nodedata["@mdatetime"] = DateTime::now().iso8601
#      puts nodedata.to_json
      query = 'CREATE (:' + nodedata['@type'].downcase + ' ?)'
#      puts query
#      begin
        @agens.execute(query, nodedata)
#      rescue
#        puts "OOPS"
#      end
    else
#      puts "Existing Node let's reuse it"
    end
  end

  def createRelation(node1,relation,node2)
  #  puts "createRelation " + relation
    query = "MATCH (n1:" + node1['@type'].downcase + "{'@id':'" + node1['@id'] + "'}) - [:" + relation + "] -> (n2:" + node2['@type'].downcase + "{'@id':'" + node2['@id'] + "'}) RETURN count(*)"
    resp = @agens.execute_query(query)
    if resp[0].count.value == 0
      query = 'MATCH (n1:' + node1['@type'].downcase + "{'@id':'" + node1['@id'] + "'}), "
      query += '(n2:' + node2['@type'].downcase + "{'@id':'" + node2['@id'] + "'})"
      query += ' CREATE (n1) - '
      query += '[:' + relation + "{'@mdatetime':'" + DateTime::now().iso8601 + "'}] -> "
      query += '(n2);'
#      puts query
      @agens.execute(query)
    end
  end

  def clearGraph
    @agens.get_vlabels_with_count().each do |node|
      query = 'MATCH (x:' + node + ') DETACH DELETE(x);'
      puts query
      @agens.execute(query)
    end
  end

  def ingest(data)
    nodedata = {}
    subnodes = {}
   
    data.each do |key,value|

      case value.class.to_s
      when 'String'
        nodedata[key] = PropertyContent.new if nodedata[key].instance_of?NilClass
        nodedata[key].content = value
      when 'Integer'
        nodedata[key] = PropertyContent.new if nodedata[key].instance_of?NilClass
        nodedata[key].content = value
      when 'Hash'
        unless value['@type'].instance_of?NilClass
          ingest(value)
          subnodes[key] = PropertyContent.new if subnodes[key].instance_of?NilClass
          subnodes[key].content = value
        end
        if value['@type'].instance_of?NilClass
          nodedata[key] = PropertyContent.new if nodedata[key].instance_of?NilClass
          nodedata[key].content = value
        end
      when 'Array'
        value.each do |v|
          case v.class.to_s
          when 'String'
            nodedata[key] = PropertyContent.new if nodedata[key].instance_of?NilClass
            nodedata[key].content = v
          when 'Integer'
            nodedata[key] = PropertyContent.new if nodedata[key].instance_of?NilClass
            nodedata[key].content = v
          when 'Hash'
            unless v['@type'].instance_of?NilClass
              ingest(v)
              subnodes[key] = PropertyContent.new if subnodes[key].instance_of?NilClass
              subnodes[key].content = v
            end
            if v['@type'].instance_of?NilClass
              nodedata[key] = PropertyContent.new if nodedata[key].instance_of?NilClass
              nodedata[key].content = v
            end
          end
        end
      end
    end

    nodedata.each do |key,value|
      nodedata[key] = value.content
    end


    if nodedata.key?("@context")
      @sdParameters.each do |key, value|
        if key == "url"
          nodedata[key] = value + nodedata["@id"] if nodedata.key?("@id")
        else
          nodedata[key] = value
        end
      end
    end

    createNode(nodedata)

    subnodes.each do |key, value|
      if value.content.instance_of?Hash
        ingest(value.content)
#        puts " "
#        puts " -> " + nodedata["@type"]
#        puts key
#        puts " => " + value.content["@type"]
        relation = @validator.findRelation(nodedata["@type"],nodedata["additionalType"], key, value.content["@type"])
        createRelation(nodedata,relation,value.content)
      end
      if value.content.instance_of?Array
        value.content.each do |value2|
          ingest(value2)
          relation = @validator.findRelation(nodedata["@type"],nodedata["additionalType"], key, value2["@type"])
          createRelation(nodedata,relation,value2)
        end
      end
    end
  end
end
