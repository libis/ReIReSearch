#encoding: UTF-8
$LOAD_PATH << '.' << './lib'
require 'logger'
require_relative './lib/loader'

##########

begin
  #output_dir = "/elastic/import"
  # every docker-container has its own HOSTNAME
  output_dir = "/elastic/import/#{ENV["HOSTNAME"]}"
  output_file = "import.bulk"

  #Create a loader object.
  loader = Loader.new()
  config = loader.config()

  loader.logger.info "use utils for es_cluster : #{loader.es_cluster}"

  if loader.es_cluster =~ /reires/i
    require_relative './utils/reires_utils'
  end
  if loader.es_cluster =~ /icandid/i
    require_relative './utils/icandid_utils'
  end

  loader.logger.info "load_type : #{loader.load_type}"

  loader.check_elastic()

  loader.direct_load = true

  start_parsing = DateTime.now.to_time
  
  case loader.load_type
  when "update"
  
    unless @direct_load 
      loader.create_import_directory()
    end
   
    #last_run = DateTime.parse(@last_run_updates).to_time
    last_run = loader.last_run_updates
  
    #total_nr_of_bulk_files = 0
    loader.logger.info "update ES config last run : #{last_run}"
    
    loader.update_bulk()
  
    unless @direct_load 
      loader.remove_import_directory()
    end

  when "reload"
    printf "\n\nWARNING - This is a full_reload 'y' to continue: "
    prompt = STDIN.gets.chomp
    return unless prompt == 'y'

    unless @direct_load 
      loader.create_import_directory()
    end
  
    #last_run = DateTime.parse(@last_run_updates).to_time
    last_run = loader.last_run_updates
  
    loader.logger.info "reload ES config last run : #{last_run}"

    loader.reload_bulk()
  
    unless @direct_load 
      loader.remove_import_directory()
    end

  when "reindex"
    printf "\n\nWARNING - This is a reindexing process\n for #{loader.es_index} on #{loader.es_cluster} [#{loader.es_url}]. 'y' to continue: "
    prompt = STDIN.gets.chomp
    return unless prompt == 'y'
    
    unless loader.check_index( loader.es_index )
      raise "Errors #{ loader.es_index  } does noet exist"
    end
  
    loader.reindex()

  else
    message = "Wrong option for load_type it must be update, reload or reindex" 
    loader.logger.warn message
    raise message
  end

  loader.updateconfig(:last_run_updates, start_parsing.to_s)

rescue StandardError => e
  puts e.message
  puts e.backtrace.inspect

  loader.logger.error e

  importance = "High"
  subject = "[ERROR] #{config[:es_cluster]} ES Loader report"
  message = <<END_OF_MESSAGE

  <h2>Error in #{loader.load_type} load_to_es for #{loader.es_index} in cluster [ #{loader.es_cluster}]</h2>
  <p>#{e.message}</p>
  <p>#{e.backtrace.inspect}</p>

  <hr>

  load_type:           #{loader.load_type}</br>
  es_cluster:          #{loader.es_cluster}</br>
  es_index:            #{loader.es_index}</br>
  record_dirs_to_load: #{loader.record_dirs_to_load}</br>
  record_pattern:      #{loader.record_pattern}</br>
  import_mappings:     #{loader.import_mappings}</br>
  import_settings:     #{loader.import_settings}</br>
  import_pipeline:     #{loader.import_pipeline}</br>

END_OF_MESSAGE

loader.mailAuditReport(subject, message, importance, config)

ensure

case loader.load_type
when "update"
  
  importance = "Normal"
  subject = "#{ config[:es_cluster] } ES Loader [#{loader.load_type}] report [#{ loader.total_nr_of_processed_files}]"

  header = "load_to_es [#{loader.load_type}] in cluster #{loader.es_cluster}, index [#{loader.es_index}]"
  params = <<END_OF_PARAMS
  load_type:           #{loader.load_type}</br>
  es_index:            #{loader.es_index}</br>
  record_dirs_to_load: #{loader.record_dirs_to_load}</br>
  record_pattern:      #{loader.record_pattern}</br>

END_OF_PARAMS

  message = "" 
  if loader.direct_load
    message += " Loaded #{ loader.total_nr_of_processed_files} records to #{ loader.es_index} in #{  loader.total_nr_of_bulk_files} load-actions"
  else
    message += " Created #{ loader.total_nr_of_processed_files} records in #{  loader.total_nr_of_bulk_files} files"
  end

when "reload"
  
  importance = "Normal"
  subject = "#{ config[:es_cluster] } ES Loader [#{loader.load_type}] report [#{ loader.total_nr_of_processed_files}]"

  header = "load_to_es [#{loader.load_type}] in cluster #{loader.es_cluster}, index [#{loader.es_index}]"
  params = <<END_OF_PARAMS
  load_type:           #{loader.load_type}</br>
  es_index:            #{loader.es_index}</br>
  record_dirs_to_load: #{loader.record_dirs_to_load}</br>
  record_pattern:      #{loader.record_pattern}</br>
  import_mappings:     #{loader.import_mappings}</br>
  import_settings:     #{loader.import_settings}</br>
  import_pipeline:     #{loader.import_pipeline}</br>

END_OF_PARAMS

  message = " Reloaded records, previous records were removed\n\n New mapping, setting and pipeline !!!" 
  if loader.direct_load
    message = " Loaded #{ loader.total_nr_of_processed_files} records to #{ loader.es_index} in #{  loader.total_nr_of_bulk_files} load-actions"
  else
    message = " Created #{ loader.total_nr_of_processed_files} records in #{  loader.total_nr_of_bulk_files} files"
  end

when "reindex"
  importance = "Normal"
  subject = "#{ config[:es_cluster] } ES Loader [#{loader.load_type}] report"
 
  header = "load_to_es [#{loader.load_type}] in cluster #{loader.es_cluster}, index [#{loader.es_index}]"
  params = <<END_OF_PARAMS
  
  load_type:           #{loader.load_type}</br>
  es_cluster:          #{loader.es_cluster}</br>
  es_index:            #{loader.es_index}</br>
  import_mappings:     #{loader.import_mappings}</br>
  import_settings:     #{loader.import_settings}</br>
  import_pipeline:     #{loader.import_pipeline}</br>

END_OF_PARAMS

  message = " Reindexed the full index #{loader.es_index} of cluster #{loader.es_cluster}"
end

message = <<END_OF_MESSAGE

<h2>#{header}</h2>

#{params}
</br>
</br>
#{message}
</br>

END_OF_MESSAGE


loader.mailAuditReport(subject, message, importance, config)

end

