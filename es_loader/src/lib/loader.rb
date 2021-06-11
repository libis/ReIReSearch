class Loader

  require 'net/smtp'
  require 'logger'
  require 'fileutils'
  require 'json'
  require 'yaml' #Used for configuration files.
  require 'pp'
  require 'date'
  require 'base64' #Needed if managing encrypted passwords.
  require 'time'
  require 'optparse'
  require 'elasticsearch'

  #Common classes
  #require_relative './reires_utils'
  #require_relative './icandid_utils'
  require_relative './es_index'
  require_relative './config'

  MAX_RESULTS_LIMIT = 300 #Number of records per file 

  attr_accessor :config, 
                :log_file, #log file.
                :logger,

                :last_run_updates, 

                :max_records_per_file,

                :direct_load,

                :record_dirs_to_load,
                :record_pattern, 

                :es_url,
                :es_version,
                :es_index,
                :es_cluster,
                :es_pipeline_id,

                :import_mappings, 
                :import_settings,
                :import_pipeline,

                :audit,

                :total_nr_of_bulk_files,
                :total_nr_of_processed_files
  
  def initialize()

    Encoding.default_external = "UTF-8"

    #@log_file             = './logs/es_loader.log'
    @log_file             = STDOUT
    @log_level            = Logger::DEBUG    
    @logger               = Logger.new(@log_file)

    @log_es_client        = false
    @client_logger        = Logger.new('./logs/es_client.log')

    @config_file          = "config.yml"

    @command_line_options = {}
    @last_run_updates     = DateTime.now.to_s

    @direct_load          = false

    @max_records_per_file = MAX_RESULTS_LIMIT
    @load_type            = "update"   # possible values: update, reload, reindex
#    @mandatory_config     = [@record_dirs_to_load,@record_pattern,@es_url,@es_version,@es_index,@es_pipeline_id,@es_cluster] 

    @mandatory_config     = []

    @record_dirs_to_load  = []
    @record_pattern       = /.*\.json/

    @temp_output_dir      = "/elastic/import/#{ENV["HOSTNAME"]}"
    @temp_output_file     = "import.bulk"

    @jsonoutput           = []

    @es_version           = nil
    @es_url               = nil
    @es_cluster           = nil
    @es_index             = nil
    @es_pipeline_id       = nil

    @es_client            = nil
    @import_mappings      = "/elastic/mappings.json"
    @import_settings      = "/elastic/settings .json"
    @import_pipeline      = "/elastic/pipeline.json"

    @audit                = {:mailfrom => "loader@example.com", :mailto => "support@example.com"}

  end

  #get configuration: default settings, command-line options, yml config-file.
  def config() 
    get_command_line_options()
    get_system_config()
    # command line options overrule config options 
    @command_line_options.each{ |o,v|
      instance_variable_set("@#{o}", v)
    }
    @logger = Logger.new(@log_file)
    @logger.debug("config_file: #{ @config_file} " )
    @logger.debug("log_file: #{ @log_file} " )
    @logger.debug("command_line_options: #{ @command_line_options} " )
    @logger.debug("record_dirs_to_load: #{ @record_dirs_to_load} " )
    
    @mandatory_config.each do |m| 
      if @config[m].nil?
        @logger.error("Mandatory config #{m} is missing")
        raise "Mandatory config #{m} is missing"
      end
    end

    @record_dirs_to_load.map! do |d|
      if Dir.glob(d).empty?
        d = "/records/#{d}"
      end
      "#{d}/**/" 
    end

    @conf = {}
    instance_variables.each do |a|
      attr_sym = a.to_s.gsub("@","").to_sym
      @conf[attr_sym] = instance_variable_get(a)
    end
    @conf

  end

  def updateconfig(field, value)
    unless @command_line_options[field]
      @config[field] = value
    else
      @logger.debug("no config update for #{field}. Was part of command line option " )
    end
  end

  # Load in the configuration file details, setting many object attributes.
  # def get_system_config(config_file = @config.config_file() ) 
  def get_system_config() 
    @config ||= Config

    @config.path = "#{File.dirname(__FILE__)}/../../config/"
    @config.config_file = @config_file

    instance_variables.each do |a|
      attr_sym = a.to_s.gsub("@","").to_sym
      unless @config[attr_sym].nil?
        instance_variable_set(a, @config[attr_sym])
      end
    end
  end

  def get_command_line_options
    # @logger.debug("get_command_line_options")
    #Defines the UI for the user. Albeit a simple command-line interface.
    OptionParser.new do |o|
      o.banner = "Usage: #{$0} [options]"

      o.on("-l LOGFILE", "--log", "write log to file") { |log_file| @log_file = log_file; @command_line_options[:log_file] = log_file }

      #Passing in a config file.... Or you can set a bunch of parameters.
      o.on("-c CONFIG", "--config", "Configuration file.") { |config_file| @config_file = config_file; @command_line_options[:config_file] = config_file  }

      o.on("-e ESLASTIC_LOGFILE", "--log", "write elastic client log to file") { |client_logger| @client_logger = client_logger; @command_line_options[:client_logger] = client_logger  }

      o.on("-d DIRECTORY", "--dir", "Sub directory relative to ./records/ \"dir1,dir2,dir3/dir\"") { |record_dirs_to_load| @record_dirs_to_load = record_dirs_to_load.split(","); @command_line_options[:record_dirs_to_load] = record_dirs_to_load.split(",") }

      o.on("-p PATTERN", "--pattern", "file pattern of record-filename /.*\\\.json/") { |record_pattern| @record_pattern = record_pattern; @command_line_options[:record_pattern] = Regexp.new(record_pattern) }

      o.on("-t LOAD_TYPE", "--load_type", "action: update, reload or reindex") { |load_type| @load_type = load_type; @command_line_options[:load_type] = load_type }

      o.on("-u LAST_RUN", "--last_run_updates", "Time the command was last run") { |last_run_updates| @last_run_updates = last_run_updates; @command_line_options[:last_run_updates] = last_run_updates }


      #Help screen.
      o.on( '-h', '--help', 'Display this screen.' ) do
        puts o
        exit
      end
      o.parse!   
    end
  end

  def load_type
    @load_type  
  end

  def load_type=(value)
    if ["update","reload","reindex"].include? (value)
      @load_type = value
    else
      message = "Wrong option for load_type it must be update, reload or reindex" 
      @logger.warn message
      raise message
    end
  end

  def mailAuditReport (subject,  report , importance, config)
    from_name = "#{config[:es_cluster]} Debugging"
    from_address = config[:audit][:mailfrom]
    to_name = "#{config[:es_cluster]}  Auditor"
    to_address = config[:audit][:mailto]
    now = DateTime.now

    message = <<END_OF_MESSAGE
From: #{from_name} #{from_address}
To: #{to_name} #{to_address}
MIME-Version: 1.0
Content-type: text/html
Subject: #{subject}
importance: #{importance}
Date: #{ now }

<H1>#{config[:es_cluster]} Audit Report</H1>

#{report}

END_OF_MESSAGE

    Net::SMTP.start('smtp.kuleuven.be', 25) do |smtp|
        smtp.send_message message,
        from_address, to_address
    end

end



  def create_import_directory
    FileUtils.mkdir_p @temp_output_dir unless Dir.exist?(@temp_output_dir)
    clear_import_directory()
  end

  def clear_import_directory
    @logger.info "clear and remove temporary output directory! #{@temp_output_dir}"
    Dir.glob("#{@temp_output_dir}/*").each { |file| File.delete(file)}
  end

  def remove_import_directory
    FileUtils.rm_rf(@temp_output_dir)
  end
  
  def update_bulk
    begin

      unless @direct_load 
        create_import_directory()
      else
        check_elastic()
      end

      @current_alias = get_current_alias()
      @logger.info "current alias for #{ @es_index } is #{@current_alias}"

      load_bulk()
      
    rescue StandardError => e
      @logger.error e
      raise e
    end
  end

  def reload_bulk
    begin

      unless @direct_load 
        create_import_directory()
      else
        check_elastic()
      end

      new_index = create_index()
      
      @current_alias = new_index
      load_bulk()

      @current_alias = get_current_alias()
      @logger.info "Replace alias for #{ @es_index }  from #{@current_alias} to #{new_index}"
      
      retval = @es_client.indices.put_alias index: new_index, name: @es_index
      if retval['errors']
        @logger.error retval
        raise "Errors in creating alias: #{retval['errors']}"
      end


      unless new_index == @current_alias
        delete_index
      end

    rescue StandardError => e
      @logger.error e
      raise e
    end
  end

  def reindex
    begin
      check_elastic()
      @current_alias = get_current_alias() 
      new_index = create_index()
      
      task_id =  @es_client.reindex(body: { source: { index: @current_alias }, dest: { index: new_index } }, wait_for_completion: false, refresh: true)['task']

      @logger.info "Reindex => task_id: #{task_id}"

      finished = false

      until finished do
        sleep  20
        @logger.debug "Reindex => task_id: #{task_id}"
        ft =  @es_client.tasks.list task_id: task_id
        @logger.debug "Reindex =>  ft: #{ft}"
        finished = ft["completed"]
      end

      @logger.info "Replace alias for #{ @es_index }  from #{@current_alias} to #{new_index}"
      retval = @es_client.indices.put_alias index: new_index, name: @es_index
      if retval['errors']
        @logger.error retval
        raise "Errors in creating alias: #{retval['errors']}"
      end

      unless new_index == @current_alias
        delete_index
      end

    rescue StandardError => e
      @logger.error e
      raise e
    end
  end
  private

  def load_bulk
    begin
      @total_nr_of_bulk_files = 0
      @total_nr_of_processed_files = 0

      lastrun = Time.parse(@last_run_updates)
      @logger.debug "lastrun        : #{ lastrun}"
      @logger.debug "@direct_load   : #{ @direct_load}"
      @logger.debug "@last_run_updates : #{@last_run_updates}"
      @logger.debug "@es_index         : #{@es_index}"
      @logger.debug "@es_pipeline_id   : #{@es_pipeline_id}"
      @logger.debug "@record_dirs_to_load  : #{ @record_dirs_to_load}"
      @logger.debug "@record_pattern   : #{ @record_pattern}"
      @logger.debug "@current_alias    : #{ @current_alias}"

      Dir.glob(@record_dirs_to_load) do |records_dir|
        @logger.info "Start processing files in #{records_dir} [#{lastrun} < File.mtime]"

        files = Dir["#{records_dir}/**/*"].select {|x| x =~ @record_pattern }
      
        @logger.info " number of files to process  : #{files.size} "

        @nr_of_processed_files = 0
        @nr_of_old_files = 0
        @nr_of_bulk_files = 0

        unless files.size == 0
          @jsonoutput = []
          files.each do |jsonfile|
            if lastrun < File.mtime(jsonfile) 
              @logger.debug jsonfile
             
              data = JSON.parse( File.read("#{jsonfile}") )
              jsondata = create_record(data)

              # Create Bulk Record Load
              @jsonoutput << {"index":{
                  "_index": @current_alias, 
                  "_type": "_doc", 
                  "pipeline": @es_pipeline_id,
                  "_id": jsondata['@id']
                  }}

              @jsonoutput << jsondata

              @nr_of_processed_files += 1

              if @nr_of_processed_files > 0 && @nr_of_processed_files % @max_records_per_file == 0
                process_bulk()
                @jsonoutput = []
              end
            else
              @nr_of_old_files += 1
            end 
          end

          process_bulk()
     
          if files.size != (@nr_of_processed_files+ @nr_of_old_files)
              raise "While parsing #{records_dir}\n Number of files to process difference from the number of records that has been loaded to ElasticSearch !\n"
          end
          @logger.debug "End processing files in #{records_dir}"
          @total_nr_of_processed_files += @nr_of_processed_files
        end
      end

      if @total_nr_of_processed_files > 0
        @logger.info "Total number of processed files : #{@total_nr_of_processed_files} chopped in #{@total_nr_of_bulk_files} pieces"
      else
        @logger.info "There was nothing to load or create !"
      end
      
    rescue StandardError => e
      @logger.error e
      raise e
    end
  end

  def process_bulk
    unless @jsonoutput.empty?
      @total_nr_of_bulk_files += 1
      @nr_of_bulk_files += 1
      if @direct_load
        load_to_es(@jsonoutput, @es_client, @logger)
        @logger.debug "Loaded #{@nr_of_processed_files} records to #{@current_alias} in #{ @nr_of_bulk_files} load-actions"
      else
        to_jsonfile(@jsonoutput, @temp_output_file , @temp_output_dir)
        @logger.debug "Created #{@nr_of_processed_files} records in #{ @nr_of_bulk_files} files"
      end
    else
      @logger.debug "jsonoutput is empty no load or file creation needed "
    end
    @logger.debug " -> @nr_of_processed_files : #{@nr_of_processed_files}"
    if @nr_of_old_files > 0
      @logger.debug " -> @nr_of_old_files file last modified before '#{@last_run_updates}' : #{@nr_of_old_files}"
    end
  end

  def delete_index
    @logger.info "Delete alias #{@es_index} from #{@current_alias} "
        retval = @es_client.indices.delete_alias index: @current_alias, name: @es_index

        if retval['errors']
          @logger.error retval
          raise "Errors in deleting : #{retval['errors']}"
        end

        printf "\n\nWARNING - Do you want to delete #{@current_alias} ? 'y' to continue: "
        prompt = STDIN.gets.chomp
        return unless prompt == 'y'

        #@logger.info "Delete index #{@current_alias}"
        #retval =  @es_client.indices.delete index: @current_alias
        #if retval['errors']
        #  @logger.error retval
        #  raise "Errors in deleting : #{retval['errors']}"
        #end
  end

end