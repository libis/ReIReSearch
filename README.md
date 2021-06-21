# “Research Infrastructure on Religious Studies” [ReIReS]

## Software architecture [ReIReS_v2.pdf](https://github.com/libis/ReIReSearch/blob/main/documentation/RelReS_v2.pdf)

## Collector [README.md](https://github.com/libis/ReIReSearch/tree/main/collector)

- Harvesting the data from different sources in different formats and store it on disk
- Convert the downloaded records to json-ld records in a schem.org format

docker-compose run data_collector ruby /app/src/collector.rb ./src/rules/<rules_set>.rb

## Agensgraph Loader [README.md](https://github.com/libis/ReIReSearch/tree/main/agensgraph_loader)

- validating schema.org json-ld records
- import/export records to and from AgensGraph

## ES loader [README.md](https://github.com/libis/ReIReSearch/tree/main/es_loader)
- Import the records, generated from AgensGraph, into an ElasticSearch index.
- Insert, Update, Reindex records in ElasticSearch

## Searchblender (federated search engine) [README.md](https://github.com/libis/ReIReSearch/tree/main/search_blender)
- send the search request to multiple seach egines (Brepols and Elasticsearch index)
- combine multiple API-responses to one response
    - combine results according to the requested sorting option
    - combine facets/aggregations
docker-compose up --build -d search_blender    

## frontend
- Web UI to interact with the search_blender API's
- docker-compose up -d front
