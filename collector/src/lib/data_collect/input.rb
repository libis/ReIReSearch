#encoding: UTF-8
require 'http'
require 'open-uri'
require 'xml_split'
require 'nokogiri'
require 'json'
require 'nori'
require 'uri'
require 'logger'
require 'cgi'
require 'mime/types'
require 'active_support/core_ext/hash'
require 'mdb'
#require_relative 'ext/xml_utility_node'

class Input
  attr_reader :raw

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def from_uri(source, options = {})
    source = CGI.unescapeHTML(source)
    @logger.info("Loading #{source}")
    uri = URI(source)
    begin
      data = nil
      case uri.scheme
        when 'http'
          data = from_http(uri, options)
        when 'https'
          data = from_https(uri, options)
        when 'file'
          data = from_file(uri, options)
        else
          raise "Do not know how to process #{source}"
      end

      data = data.nil? ? 'no data found' : data

      if block_given?
        yield data
      else
        data
      end
    rescue => e
      @logger.info(e.message)
      puts e.backtrace.join("\n")
      nil
    end
  end


  def csv_file_to_hash(file, col_sep = ",")
    begin
        puts "csv_file_to_hash #{file}"
        data = CSV.read(file, headers: true, col_sep: col_sep)
  #      puts data.first.to_h
        data
    rescue StandardError => msg
        puts msg
        puts "Error csv_file_to_hash: unable to read CSV #{file}"            
        {}
    end
  end  

  def mdb_to_hash(file)
    begin
        data = Mdb.open(file)
        data
    rescue StandardError => msg
        puts msg
        puts "Error mdb_to_hash: unable to read Mdb #{file}"            
        {}
    end
  end  


  private
  def from_http(uri, options = {})
    from_https(uri, options)
  end

  def from_https(uri, options = {})
    data = nil
    raise "User or Password parameter not found" unless options.keys.include?(:user) && options.keys.include?(:password)
    user = options[:user]
    password = options[:password]
    http_response = HTTP.basic_auth(user: user, pass: password).get(escape_uri(uri))
    case http_response.code
      when 200
        @raw = data = http_response.body.to_s
       # File.open("#{rand(1000)}.xml", 'wb') do |f|
       #   f.puts data
       # end
        file_type = file_type_from(http_response.headers)
        unless options.with_indifferent_access.has_key?(:raw) && options.with_indifferent_access[:raw] == true
          case file_type
            when 'applicaton/json'
              data = JSON.parse(data)
            when 'application/atom+xml'
              data = xml_to_hash(data)
            when 'application/xml'
            when 'text/xml'
              data = xml_to_hash(data)
            else
              data = xml_to_hash(data)
          end
        end
      when 401
        raise 'Unauthorized'
      when 404
        raise 'Not found'
      else
        raise "Unable to process received status code = #{http_response.code}"
    end

    data
  end

  def from_file(uri, options = {})
    data = nil
    absolute_path = File.absolute_path("#{uri.host}#{uri.path}")
    unless options.has_key?('raw') && options['raw'] == true
      @raw = data = File.read("#{absolute_path}")
      case File.extname(absolute_path)
        when '.json'
          @raw = data = File.read("#{absolute_path}")
          data = JSON.parse(data)
        when '.xml'
          @raw = data = File.read("#{absolute_path}")
          data = xml_to_hash(data)
        when '.csv'
          data = csv_file_to_hash(absolute_path)             
        when '.mdb'
          data = mdb_to_hash(absolute_path)          
        else
          raise "Do not know how to process #{uri.to_s}"
      end
    end

    data
  end


  private
  def xml_to_hash(data)
    #gsub('&lt;\/', '&lt; /') outherwise wrong XML-parsing (see records lirias1729192 )
    #  data = data.gsub /&lt;/, '&lt; /'
    nori = Nori.new(parser: :nokogiri, strip_namespaces: true, convert_tags_to: lambda {|tag| tag.gsub(/^@/, '_')})
    nori.parse(data)
    #JSON.parse(nori.parse(data).to_json)
  end

  def escape_uri(uri)
    #"#{uri.to_s.gsub(uri.query, '')}#{CGI.escape(CGI.unescape(uri.query))}"
    uri.to_s
  end

  def file_type_from(headers)
    file_type = 'application/octet-stream'
    file_type = if headers.include?('Content-Type')
                  headers['Content-Type'].split(';').first
                else
                  MIME::Types.of(filename_from(headers)).first.content_type
                end

    return file_type
  end

end