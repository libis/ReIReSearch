class AgensBrowser
  def initialize
    api_base_uri = 'http://localhost:8085/api'
    @api_connect_uri = api_base_uri + '/auth/connect'
    @api_query_uri = api_base_uri + '/core/query'
    @api_schema_uri = api_base_uri + '/core/schema'
    @api_disconnect_uri = api_base_uri + '/auth_disconnect'
  end
  def connect
    uri = URI(@api_connect_uri)
    auth = JSON.parse(Net::HTTP.get(uri))
    if (auth["valid"])
      @ssid = auth["ssid"]
    else
      raise "Unable to connect to AgensBrowser (invalid)"
    end
  end

  def disconnect
    uri = URI.parse(@api_disconnect_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Authorization"] = @ssid
    request["Accept"] = "application/json"
    response = http.request(request)
#    puts response.body
  end

  def query(q)
#    puts q
    uri = URI.parse(@api_query_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri+"?sql=" + URI.escape(q))
    request["Authorization"] = @ssid
    request["Accept"] = "application/json"
    response = http.request(request)

    puts "========================================================="
    puts response.body
    puts "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    return JSON.parse(response.body)
  end

  def schema
    uri = URI.parse(@api_schema_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Authorization"] = @ssid
    request["Accept"] = "application/json"
    response = http.request(request)
#    puts response.body
    return JSON.parse(response.body)
  end

end
