require "pp"
require "java"
require "json"
require_relative "./java/agensgraph-jdbc-1.4.2-c1.jar"
require 'ostruct'

java_import "java.sql.DriverManager"
java_import "java.sql.Connection"
java_import "java.sql.PreparedStatement"
java_import "net.bitnine.agensgraph.Driver"
java_import "net.bitnine.agensgraph.util.Jsonb"
java_import "net.bitnine.agensgraph.util.JsonbUtil"

class AgensGraph
  def initialize(host='localhost',port=5432)
    @connectionString = "jdbc:agensgraph://" + host + ":" + port.to_s + "/agens"
  end

  def connect (username, password)
    @connection = DriverManager.get_connection(@connectionString, username, password)
  end

  def execute(query, data = nil)
#    puts "execute : " + query
    if data.nil?
      stmt = @connection.create_statement
      stmt.execute(query)
    else
      stmt = @connection.prepare_statement(query)
      j = JsonbUtil::createObjectBuilder()
      data.each do |k, v|
        j.add(k,v)
      end
      stmt.set_object(1,j.build())
      stmt.execute()
    end
  end

  def execute_query(query)
#    puts "execute_query : " + query
    stmt = @connection.create_statement
    rs = stmt.execute_query(query)

    results = Array.new
    while (rs.next())
      st = OpenStruct.new
      (1..rs.getMetaData.getColumnCount).each do |col|
        struct = OpenStruct.new
        begin
          rs.getObject(col).properties.json_value.each do |k,v|
            if k[0] == "@"
              k = 'at_' + k[1,k.length-1]
            end
            struct[k] = v
          end
        rescue NoMethodError
          struct[:value] = rs.getObject(col).jsonValue unless  rs.getObject(col).nil?
        end
        st[rs.getMetaData.getColumnLabel(col)]= struct
      end
      results.push(st)
    end
    results
  end

  def set_graph(graph)
    self.execute("SET graph_path = " + graph)
  end

  def get_graphpath()
    stmt = @connection.create_statement
    rs = stmt.execute_query("SHOW graph_path")
    rs.next()
    graph_path = rs.getString("graph_path")
    graph_path
  end

  def get_vlabels()
    graph_path = self.get_graphpath()
    self.execute("SET search_path TO E'" + graph_path + "', E'public'")

    query = "SELECT l.labid as la_oid, l.labname as la_name
FROM pg_catalog.ag_label l INNER JOIN pg_catalog.ag_graph g ON g.oid = l.graphid
LEFT OUTER JOIN pg_catalog.pg_class c ON c.oid = l.relid
LEFT OUTER JOIN pg_stat_user_tables u on u.relid = l.relid
WHERE g.graphname = '" + graph_path + "' AND l.labkind = 'v' and l.labname not in ('ag_vertex', 'ag_edge') ORDER BY l.labid"
    stmt = @connection.create_statement
    rs = stmt.execute_query(query)
    results = Array.new
    while (rs.next())
      results.push(rs.getString("la_name"))
    end
    results
  end

  def get_vlabels_with_count()
    querys = []
    vlabels = self.get_vlabels()
    vlabels.each do |node|
      querys.push("select '" + node + "' as la_name, count(*) as c from " + node)
    end
    query = querys.join(" UNION ") + " order by 2 asc"

    stmt = @connection.create_statement
    rs = stmt.execute_query(query)
    results = Array.new
    while (rs.next())
      results.push(rs.getString("la_name"))
    end
    results
  end

  def get_elabels()
    graph_path = self.get_graphpath()
    self.execute("SET search_path TO E'" + graph_path + "', E'public'")

    query = "SELECT l.labid as la_oid, l.labname as la_name
FROM pg_catalog.ag_label l INNER JOIN pg_catalog.ag_graph g ON g.oid = l.graphid
LEFT OUTER JOIN pg_catalog.pg_class c ON c.oid = l.relid
LEFT OUTER JOIN pg_stat_user_tables u on u.relid = l.relid
WHERE g.graphname = '" + graph_path + "' AND l.labkind = 'e' and l.labname not in ('ag_vertex', 'ag_edge') ORDER BY l.labid"
    stmt = @connection.create_statement
    rs = stmt.execute_query(query)
    results = Array.new
    while (rs.next())
      results.push(rs.getString("la_name"))
    end
    results
  end


end
