#encoding: UTF-8
require 'nokogiri'
require 'erb'
require 'date'
require 'minitar'
require 'zlib'
require 'cgi'
require 'active_support/core_ext/hash'
require 'fileutils'


class Output
  include Enumerable
  attr_reader :data, :tar_file

  def initialize(data = {})
    @data = data
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def each
    @data.each do |d|
      yield d
    end
  end

  def [](k,v = nil)
    data[k]
  end

  def []=(k,v = nil)
    unless v.nil? || v.empty?
      if data.has_key?(k)
        data[k] = [data[k]] if !data[k].is_a?(Array)
        data[k] << v
      else
        data[k] = v
      end
    end
    data[k] = data[k].flatten.compact if data[k].is_a?(Array)
    data
  end

  def raw
    @data
  end

  def clear
    @data = {}
  end

  def to_s(erb_file)
    data = @data
    def print(data, symbol, to_symbol = nil)
      tag = to_symbol ? to_symbol.to_s : symbol.to_s

      if data.with_indifferent_access[symbol]
        if data.with_indifferent_access[symbol].is_a?(Array)
          r = []
          data.with_indifferent_access[symbol].each do |d|
            r << "<#{tag}>#{CGI.escapeHTML(d.to_s)}</#{tag}>"
          end
          r.join("\n")
        elsif data.with_indifferent_access[symbol].is_a?(Hash)
          r = []
          r << "<#{tag}>"
          data.with_indifferent_access[symbol].keys.each do |k|
            r << print(data.with_indifferent_access[symbol], k)
          end
          r << "</#{tag}>"
          r.join("\n")
        else
          "<#{tag}>#{CGI.escapeHTML(data.with_indifferent_access[symbol].to_s)}</#{tag}>"
        end
      else
        nil
      end
    rescue Exception => e
      @logger.error("unable to print data '#{symbol}'")
    end

    def no_tag_print(data, symbol)
      if data.with_indifferent_access[symbol]
        if data.with_indifferent_access[symbol].is_a?(Array)
          r = []
          data.with_indifferent_access[symbol].each do |d|
            r << "#{CGI.escapeHTML(d.to_s)}"
          end
          r.join(",\n")
        else
          "#{CGI.escapeHTML(data.with_indifferent_access[symbol].to_s)}"
        end
      else
        nil  
      end
    rescue Exception => e
      @logger.error("unable to print (without tag) data '#{symbol}'")
    end
      
    data[:response_date] = DateTime.now.xmlschema

    result = ERB.new(File.read(erb_file), 0, '>').result(binding)

    result
  rescue Exception => e
    raise "unable to transform to text: #{e.message}"
    ""
  end

  def to_tmp_file(erb_file,records_dir)
    id = data[:id].first rescue 'unknown'
    result = to_s(erb_file)
    xml_result = Nokogiri::XML(result, nil, 'UTF-8') do |config|
      config.noblanks
    end

    unless File.directory?(records_dir)
      FileUtils.mkdir_p(records_dir)
    end

    file_name = "#{records_dir}/#{id}_#{rand(1000)}.xml"
    
    File.open(file_name, 'wb:UTF-8') do |f|
      f.puts xml_result.to_xml
    end
    return file_name
  end

  def to_file(erb_file, records_dir = 'records', tar_file_name = nil)
    id = data[:id].first rescue 'unknown'
    result = to_s(erb_file)

    xml_result = Nokogiri::XML(result, nil, 'UTF-8') do |config|
      config.noblanks
    end

    if tar_file_name.nil?
      file_name = "#{records_dir}/#{id}_#{rand(1000)}.xml"
      File.open(file_name, 'wb:UTF-8') do |f|
        f.puts xml_result.to_xml
      end

      return file_name
    else

      Minitar::Output.open(Zlib::GzipWriter.new(File.open("#{records_dir}/#{tar_file_name}", 'wb:UTF-8'))) do |f|
        xml_data = xml_result.to_xml
        f.tar.add_file_simple("#{id}_#{rand(1000)}.xml", data: xml_data, size: xml_data.size, mtime: Time.now.to_i)
      end

      return tar_file_name
    end

  rescue Exception => e
    raise "unable to save to file: #{e.message}"
  end

  def to_json (jsonfile, records_dir = 'records')
    id = data[:id].first rescue 'unknown'
    result = data.to_json.force_encoding('UTF-8').gsub("\u2028", '').gsub("\u2029", '').gsub("\u0085", '')
    unless File.directory?(records_dir)
      FileUtils.mkdir_p(records_dir)
    end
    file_name = "#{records_dir}/#{jsonfile}_#{Time.now.to_i}_#{rand(1000)}.json"
    File.open(file_name, 'wb') do |f|
      f.puts result
    end
  rescue Exception => e
    raise "unable to save to jsonfile: #{e.message}"
  end


  def to_jsonfile (jsondata, jsonfile, records_dir = 'records')
    unless File.directory?(records_dir)
      FileUtils.mkdir_p(records_dir)
    end
    file_name = "#{records_dir}/#{jsonfile}_#{Time.now.to_i}_#{rand(1000)}.json"
    File.open(file_name, 'wb') do |f|
      f.puts jsondata.to_json.force_encoding('UTF-8').gsub("\u2028", '').gsub("\u2029", '').gsub("\u0085", '')
    end
  rescue Exception => e
    raise "unable to save to jsonfile: #{e.message}"
  end


  def add_all_ids( prefix:, counter_start: {}, context: "http://schema.org")
    add_id(data, prefix, counter_start, context)
  end

  def clean
    cleanup(data)
  end

  private
  def tar_file(tar_file_name)
    @tar_file ||= Minitar::Output.open(File.open("records/#{tar_file_name}", "a+b"))
  end

  def cleanup(s)
    if s.is_a?(Hash)
      #puts " - Hash - #{s}"
      s.reject!{|k,v| 
        v.nil? || 
        ( (!v.is_a? Integer) && v.empty? )  || 
        ( v.is_a?(Hash) && v.has_key?("name") && v["name"].empty? ) 
      }
      s.compact!
      s = s.each { |k, v| s[k] = cleanup(v) }
      s.compact!
      s
      #puts " - Hash End - #{s}"
    elsif s.is_a?(Array)
        #puts " - Array - #{s}"
        s.compact!
        s = s.each { |v| cleanup(v) }
        s.compact!
        s = s.empty? ? nil : s.compact
        unless s.nil?
          s = s.size == 1 ? s[0] : s
        end
        #puts " - Array End - #{s}"
        s
    elsif s.is_a?(String)
      #puts " - String - #{s}"
      s = s.blank? ? nil : s
      #puts " - String End - #{s}"
      s
    else
      s
    end
  end

  def add_id( inputdata, prefix, counter_start = {}, context = "http://schema.org") 
    begin
      if inputdata.is_a?(Hash)
        # Add @contect to book / volume / article / mediaobjectt / event.....
        unless inputdata['@type'].nil?
          if ['book', 'publicationvolume', 'publicationissue', 'volume', 'article', 'mediaobject', 'event' ].include? inputdata['@type'].downcase
            if inputdata["@context"].nil?
              inputdata["@context"] = context
            else
              context = inputdata["@context"]
            end
          end
        end
          # hash with @language property do not need an id (example: 
          #   "@context" => [
          #      "http://schema.org", 
          #      {  "@language" => "de" }
          #    ]
        if inputdata[:@language].nil?
          counter_start[ inputdata[:@type] ].nil? ?  counter_start[ inputdata[:@type] ] = 0 : counter_start[ inputdata[:@type] ] = counter_start[ inputdata[:@type] ] +1
          if inputdata[:@id].nil? || inputdata[:@id].empty?
            unless inputdata.empty?
              inputdata[:@id] = "#{prefix}_#{ inputdata[:@type].upcase }_#{ counter_start[ inputdata[:@type] ] }"
    #          @logger.info(" -- inputdata = id --- #{prefix}_#{ inputdata['@type'].upcase }_#{ counter_start[ inputdata['@type'] ] } ") 
            end
          end
          inputdata.each do |k, v|
            ## @context doesn't need an additional @id 
            unless k.to_s == "@context" 
              if v.is_a?(Hash) || v.is_a?(Array)
                add_id(  v, prefix, counter_start, context)
              end
            end
          end
        end
      end
      if inputdata.is_a?(Array)
        inputdata.each do |d|
          add_id(  d, prefix, counter_start, context)
        end
      end
    end
  rescue => e
    @logger.info(e.message)
    puts e
    #puts inputdata
    puts e.backtrace.join("\n")
    nil 
    exit
  end
end
