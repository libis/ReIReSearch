# **schema.org validator, load and export for AgensGraph **

## Start AgensGraph
docker-compose up -d agensgraph

## Validating data
Validating records from datain agains the validation.json file

docker-compose run --rm agensgraph_loader jruby reiresbatch.rb validate &lt;folder&gt;

Example : docker-compose run --rm agensgraph_loader jruby reires_batch.rb validate ../datain/DHGE

Note : subfolders do not get validated

## Create a script to create a reires_graph 
docker-compose run --rm agensgraph_loader jruby graph_generator.rb

## Create reires_graph
docker-compose run --rm agensgraph_loader jruby reires_batch.rb create

## Empty reires_graph
docker-compose run --rm agensgraph_loader jruby reires_batch.rb clear

Warning : this deletes all data, no warning of this is given by the script !!!!!

## Load to reires_graph
docker-compose run agensgraph_loader jruby reires_batch.rb load &lt;folder&gt;

Example : docker-compose run --rm agensgraph_loader jruby reires_batch.rb load ../datain/DHGE

Note : subfolders do not get loaded

## Export from reires_graph
docker-compose run -rm agensgraph_loader jruby /app/src/reires_export.rb &lt;folder&gt; &lt;type&gt;
Example : docker-compose run -rm agensgraph_loader jruby reires_export.rb ruby reires_export.rb DHGE CreativeWork 

