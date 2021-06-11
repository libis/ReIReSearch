# ** LOAD RECODS TO ELASTIC SEARCH **
Prepare record and load records to elasticsearch

Check Networksettings in docker-compose !!! 
es_loader_container must be able to connect to the elastic search container

## Build the docker image and install all gems
$ docker-compose up -d --build

## Configuration and/or Command Line options for load_to_es.rb 
The configuration determines
- Elastic connection, cluster and index
- mappings, settings, ...

Command Line options
- -c <CONFIG FILE> specify a config file to use (default is config.yml)  
- -d <DIRECTORY> specify a list directories of the json-records which must be uploaded to elasticsearh  
   or inside config-file with parameter record_dirs_to_load  
- -p <PATTERN> file pattern of record-filename of the json-records which must be uploaded to elasticsearh  
   or inside config-file with parameter record_pattern  
- -l <FILENAME> filename off the log-file  
   or inside config-file with parameter log_file  
- -t <load_type> action that has to be executed (update, reload or  reindex)  
   or inside config-file with parameter load_type  
- -e <FILENAME> filename off the log-file of the elasticsearch client (default is /logs/es_client.log)  
- -u <LAST_RUN> Time the command was last run. Only load records with a modification date after this time  
   :last_run_updates will NOT be updated if this option is set in the command line  

the config file (or options) contains the load_type (update, reload, reindex are the posible value)  

### update:
load all records based on 
-- :record_dirs_to_load  
-- :record_pattern  
-- :modification time (File.mtime) > :last_run_updates  

### reload:
create a new index and load it with the records based on   
-- :record_dirs_to_load  
-- :record_pattern  
-- :modification time (File.mtime) > :last_run_updates  
after loading and indexing the alias is set and the old index is deleted  

### reindex:
will create a new index (setting, mappings, ...) and after indexing sets the alias to the es_index value.

### todo ?
- Delete by query
- direct_load 

## Examples
=> ruby ./src/load_to_es.rb -c es_test_loader_config.yml -d  
=> ruby ./src/load_to_es.rb -c es_test_loader_config.yml -t reindex  
=> ruby ./src/load_to_es.rb -c es_test_loader_config.yml -t update -d JGU_Mainz -u '2021-03-15 16:00'  
=> docker-compose run elastic_loader ruby ./src/load_to_es.rb -c es_test_loader_config.yml -t update -d JGU_Mainz -u '2021-03-15 16:00'  
=> docker-compose run elastic_loader ruby ./src/load_to_es.rb -c es_test_loader_config.yml -t reindex
=> docker-compose run elastic_loader ruby ./src/load_to_es.rb -c es_test_loader_config.yml -t update -d "Klerus_Datenbank" -p ".*_PERSON_.*\.json" -u '2021-03-15 16:00'