# **DATA_COLLECT Library**

## harvesting/collecting data
Records can be harvested via:
- ftp
- url [http(s)] (example: 'https://gutenberg-capture.ub.uni-mainz.de/ubmzms/oai?verb=ListRecords' )
- directly from disk

Sources can also be harvested periodically. The parameter last_run_updates determines which files will be collected. This parameter is configured along with other options (ftp-server, parth, username, password, ...) in a yml-config file.
The source-records are stored in the directory ./source_records/<source_name>

Every source has its own rules. Each rule will use an ingestConfJson-file. This file contains some default values for the source like values for the isBaseOn property, value for the licence, default metaLanguage and unicode_script, ...


Records will be converted to json-ld schema.org format and stored in the directory ./records/<source_name>

## Starting a collector:
docker-compose run data_collector ruby /app/src/collector.rb ./src/rules/<rules_set>.rb

### examples
=> docker-compose run --rm data_collector ruby /app/src/collector.rb ./src/rules/Alma_KULeuven_MauritsSabbe.rb  
=> docker-compose run --rm data_collector ruby /app/src/collector.rb ./src/rules/Alma_KULeuven_Bij_Col.rb  
=> docker-compose run --rm data_collector ruby /app/src/collector.rb ./src/rules/Alma_KULeuven_LSIN.rb  
=> docker-compose run --rm data_collector ruby /app/src/collector.rb ./src/rules/JGU_Mainz.rb  
=> docker-compose run --rm data_collector ruby /app/src/collector.rb ./src/rules/BookLibrary_Cyrillomethodiana.rb  
=> docker-compose run --rm data_collector ruby /app/src/collector.rb ./src/rules/FSCIRE_Mansi.rb  
=> docker-compose run --rm data_collector ruby /app/src/collector.rb ./src/rules/DHGE.rb  
=> docker-compose run --rm data_collector ruby /app/src/collector.rb ./src/rules/Klerus_Datenbank.rb  


## Rules
- Alma_KULueven_Bij_Col.rb, Alma_KULueven_LSIN.rb, Alma_KULueven_MauritsSabbe.rb: Manage the harvesting of Alma MARC21-xml records from an ftp-server
- Alma_KUleuven.rb : converting MARC21-xml
- BookLibrary_Cyrillomethodiana.rb : converting custom xml; transforms code to language specific string based on ./config/Cyrillomethodiana/category.json
- DHGE.rb : starts from json data. Just make some small changes and add ingest data.
- FSCIRE_Mansi.rb : converting multiple csv-files. The csv files are linked together via IDs in specific columns
- JGU_Mainz.rb : harvesting and converting mets via OAI
- Klerus_Datenbank.rb : converting mdb-file (access database)

## schema.org
The generated schema.org records are multilingual and have different scripting (hebrew latin Cyrillisch). Therefore some properties will not just contain a value but a hash with 2 properties; @value and @language. More information about this at https://json-ld.org/spec/latest/json-ld/#string-internationalization and https://www.w3.org/TR/string-meta/#script_subtag