#encoding: UTF-8
require 'active_support/core_ext/hash'
require 'jsonpath'
require 'logger'

require "iso639"

require_relative 'data_collect/config_file'
require_relative 'data_collect/input'
require_relative 'data_collect/output'
require_relative 'data_collect/utils'


require_relative 'data_collect/ext/xml_utility_node'
require 'lib/monkey_jsonpath_1.0.4'

class DataCollect
  attr_reader :input, :output

  include Utils
  
  def initialize
    Encoding.default_external = "UTF-8"
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def runner(rule_file_name)
    @time_start = Time.now
    prg = self
    prg.instance_eval(File.read(rule_file_name))
    prg
  rescue Exception => e
    puts e.message
    puts e.backtrace.join("\n")
    
  ensure
#    output.tar_file.close unless output.tar_file.closed?
    @logger.info("Finished in #{((Time.now - @time_start)*1000).to_i} ms")
  end

  #These functions are available to your rules file
  private
  # Read input from an URI
  # example:  input.from_uri("http://www.libis.be")
  #           input.from_uri("file://hello.txt")
  def input
    @input ||= Input.new
  end

  # Output is an object you can store data that needs to be written to an output stream
  # output[:name] = 'John'
  # output[:last_name] = 'Doe'
  #
  # Write output to a file, string use an ERB file as a template
  # example:
  # test.erb
  #   <names>
  #     <combined><%= data[:name] %> <%= data[:last_name] %></combined>
  #     <%= print data, :name, :first_name %>
  #     <%= print data, :last_name %>
  #   </names>
  #
  # will produce
  #   <names>
  #     <combined>John Doe</combined>
  #     <first_name>John</first_name>
  #     <last_name>Doe</last_name>
  #   </names>
  #
  # Into a variable
  # result = output.to_s("test.erb")
  # Into a file stored in records dir
  # output.to_file("test.erb")
  # Into a tar file stored in data
  # output.to_file("test.erb", "my_data.tar.gz")
  # Into a temp directory 
  # output.to_tmp_file("test.erb","directory")
  def output
    @output ||= Output.new
  end

  # evaluator http://jsonpath.com/
  # uitleg http://goessner.net/articles/JsonPath/index.html
  def filter(data, filter_path)

    filtered = []
    if filter_path.is_a?(Array) && data.is_a?(Array)
      filtered = data.map{|m| m.select{|k,v| filter_path.include?(k.to_sym)}}
    elsif filter_path.is_a?(String)
      filtered = JsonPath.on(data, filter_path)
    end

    filtered = [filtered] unless filtered.is_a?(Array)
    filtered = filtered.first if filtered.length == 1 && filtered.first.is_a?(Array)
    #filtered = filtered.empty? ? nil : filtered

    filtered
  rescue Exception => e
    @logger.error("#{filter_path} failed: #{e.message}")
    return []
  end

  def config
    @config ||= ConfigFile
  end

  def log(message)
    @logger.info(message)
  end

  def add_ids(data:, prefix:, counter_start: '0') 
    #log ( "add_ids : #{counter_start} ")
    data.to_a.each do |d|
        d['@id'] = "#{prefix}_#{counter_start}"
        # @logger.info(" ----- #{ d['@type'] } ")
        counter_start += 1
    end unless nil?
    @counter = counter_start
  end

  def add_all_ids(data:, prefix:, counter_start: {}, context: "http://schema.org") 

    if data.is_a?(Hash)
      # Add @contect to book / volume / article / mediaobjectt / event.....
      unless data['@type'].nil?
        if ['book', 'publicationvolume', 'publicationissue', 'volume', 'article', 'mediaobject', 'event' ].include? data['@type'].downcase
          if data["@context"].nil?
            data["@context"] = context
          else
            context = data["@context"]
          end
        end
      end
        # hash with @language property do not need an id (example: 
        #   "@context" => [
        #      "http://schema.org", 
        #      {  "@language" => "de" }
        #    ]
      if data[:@language].nil?
        counter_start[ data['@type'] ].nil? ?  counter_start[ data['@type'] ] = 0 : counter_start[ data['@type'] ] = counter_start[ data['@type'] ] +1
        if data["@id"].nil? || data["@id"].empty?
          unless data.empty?
            data['@id'] = "#{prefix}_#{ data['@type'].upcase }_#{ counter_start[ data['@type'] ] }"
  #          @logger.info(" -- data = id --- #{prefix}_#{ data['@type'].upcase }_#{ counter_start[ data['@type'] ] } ") 
          end
        end
        data.each do |k, v|
          ## @context doesn't need an additional @id 
          unless k.to_s == "@context" 
            if v.is_a?(Hash) || v.is_a?(Array)
              add_all_ids( data: v, prefix:  prefix, counter_start: counter_start, context: context)
            end
          end
        end
      end
    end
    if data.is_a?(Array)
      data.each do |d|
        add_all_ids( data: d, prefix:  prefix, counter_start: counter_start, context: context)
      end
    end
  end


  def join_tables(data, source_table, source_column, table, column)
    source_table.map! { |e| 
      unless  e[source_column].nil?
        s = data[table].select { |c| 
          c[column] == e[source_column]
        }
        if s.size > 1
                puts "HELP join_tables in data_collect.rb !!!!!!! #{s}"
        end
        e[source_column] = s.first
      end
      e
    }
  end

end