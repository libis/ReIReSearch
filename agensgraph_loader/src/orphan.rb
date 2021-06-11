require './lib/agensgraph'

host = 'agensgraph'
username = 'agens'
password = 'agens'
graph = 'reires_graph'


starttime = Time.now
@agens = AgensGraph.new(host)
@agens.connect(username, password)
@agens.set_graph(graph)



query = "match (t:Thing) return t.'@id'"
list = @agens.execute_query(query).map { |l| l["@id"].value }

list.each do |id|

  q1 = "match (t:Thing{'@id':'" + id + "'}) - [] -> (s:Thing) return count(s)"
  res1 = @agens.execute_query(q1)

  q2 = "match (t:Thing{'@id':'" + id + "'}) <- [] - (s:Thing) return count(s)"
  res2 = @agens.execute_query(q2)

  if (res1.count + res2.count) == 0 
	puts id
  end

end
