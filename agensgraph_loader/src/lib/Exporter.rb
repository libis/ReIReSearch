class Exporter
  def initialize(host,username,password, graph)
    @agens = AgensGraph.new(host)
    @agens.connect(username, password)
    @agens.set_graph(graph)
    @validator = Validator.new
  end

  def export(type, additionaltype, id)
    struct = {}

    if additionaltype == "" || additionaltype.nil?
      relations = @validator.findRelations(type)
    else
      relations = (@validator.findRelations(type) + @validator.findRelations(additionaltype)).uniq
    end

    query = 'MATCH (d:' + type + " {'@id':'" + id + "'}) RETURN *"
    list = @agens.execute_query(query)

    list.each do |values|
      values.d.each_pair do |k,v|
        if k[0,3] == 'at_'
          k = '@' + k[3,k.length-3]
        end
        if (k != "@mdatetime" && k != "@maindocument")
          case v.class.to_s
          when "String"
            struct[k] = v
          when "Integer"
            struct[k] = v
          when "Java::NetBitnineAgensgraphDepsOrgJsonSimple::JSONArray"
            struct[k] = self.processJSONArray(v)
          when "Java::NetBitnineAgensgraphDepsOrgJsonSimple::JSONObject"
            struct[k] = self.processJSONObject(v)
          else
            puts "Export doesn't know what to do with " + v.class.to_s
          end
        end
      end
    end

    relations.each do |rel|
      query = 'MATCH (d:' + type + " {'@id':'" + id + "'}) - [r:" + rel[1] + '] -> (o:' + rel[2] + ') RETURN o'
      list = @agens.execute_query(query)

      if list.count > 0
        list.each do |values|
          unless values.o.at_type.instance_of?NilClass
            if (values.o.at_type == rel[2])
              if (struct[rel[0]].instance_of?NilClass)
                struct[rel[0]] = export(values.o.at_type, values.o.additionaltype, values.o.at_id)
              else
                if (struct[rel[0]].instance_of?Array)
                  struct[rel[0]].push(export(values.o.at_type, values.o.additionaltype, values.o.at_id))
                else
                  tmp = struct[rel[0]]
                  struct[rel[0]] = []
                  struct[rel[0]].push(tmp)
                  struct[rel[0]].push(export(values.o.at_type, values.o.additionaltype, values.o.at_id))
                end
              end
            end
          end
        end
      end

=begin
      if list.count > 0
        if list.count == 1
          list.each do |values|
            struct[rel[0]] = export(values.o.at_type, values.o.additionaltype, values.o.at_id) unless values.o.at_type.instance_of?NilClass
          end
        else
          struct[rel[0]] = []
          list.each do |values|
            struct[rel[0]].push(export(values.o.at_type, values.o.additionaltype, values.o.at_id)) unless values.o.at_type.instance_of?NilClass
          end
        end
      end

=end
    end
    struct
  end

  def processJSONObject(obj)
    hash = {}
    obj.each do |k,v|
      case v.class.to_s
      when "String"
        hash[k] = v
      when "Integer"
        hash[k] = v
      when "Java::NetBitnineAgensgraphDepsOrgJsonSimple::JSONObject"
        hash[k] = processJSONObject(v)
      when "Java::NetBitnineAgensgraphDepsOrgJsonSimple::JSONArray"
        hash[k] = processJSONArray(v)
      else
        puts "ProcessJSONOject doesn't know what to do with " + v.class.to_s
      end
    end
    return hash
  end

  def processJSONArray(arr)
    out = []
    arr.each do |v|
      case v.class.to_s
      when "String"
        out << v
      when "Integer"
        out << v
      when "Java::NetBitnineAgensgraphDepsOrgJsonSimple::JSONObject"
        out << processJSONObject(v)
      when "Java::NetBitnineAgensgraphDepsOrgJsonSimple::JSONArray"
        out << processJSONArray(v)
      else
        puts "ProcessJSONArray doesn't know what to do with " + v.class.to_s
      end
    end
    return out
  end


end
