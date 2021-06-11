# Es-loader
Prepare record and load records to elasticsearch

# ruby ./src/create_bulk.rb 
# -c <CONFIG FILE> specify a config file to use (default is config.yml)

# -d <DIRECTORY> specify a list directories of the json-records which must be uploaded to elasticsearh
#   or inside config-file with parameter record_dirs_to_load
# -p <PATTERN> file pattern of record-filename of the json-records which must be uploaded to elasticsearh
#   or inside config-file with parameter record_pattern
# -l <FILENAME> filename off the log-file
#   or inside config-file with parameter log_file
# -t <load_type> action that has to be executed (update, reload or  reindex)
#   or inside config-file with parameter load_type
# -e <FILENAME> filename  off the log-file of the elasticsearch client (default is /logs/es_client.log)
# -u <LAST_RUN> Time the command was last run. Only load records with a modification date after this time
# 
# The configuration determines
# => Elastic connection, cluster and index
# => mappings, settings, ...

# the config file also contains te load_type
# update, reload, reindex are the posible values

# update:
# load all records based on :record_dirs_to_load and :record_pattern that have an modification time (File.mtime) that later than :last_run_updates

# reload:
# creates a new index and load it with the records based on :record_dirs_to_load and :record_pattern and :last_run_updates
# after loading and indexing the alias is set and the old index is deleted

# reindex:
# will create a new index (settin, mappings, ...) and after indexing sets the alias to the es_index value. 

# ?????? Delete by query
# ?????? direct_load ??????

# Examples
=> ruby ./src/load_to_es.rb -c es_test_loader_config.yml -d Twitter
=> ruby ./src/load_to_es.rb -c es_test_loader_config.yml -t reindex
=> ruby ./src/load_to_es.rb -c es_test_loader_config.yml -t update -d twitter -u '2021-03-15 16:00'