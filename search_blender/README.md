# ** FEDERATED SEARCH (Crytal) **

## Build the docker image and install all gems
$ docker-compose up --build

# Configuration 
- reires.json:  
Overall configuration of the blender  
-- set environment to development to use other config file from subdirectory ./config/development  
-- search_indexes : supported indexes of saerch_blender  
-- datamodel_constants : some parameters that can be added to records from an external source (not ReIReS ES-index)  

- reires_search_engines.json:  
Every source has its own engine. Currently there are 2 engines: ReIReS ES-index (elastic) and Brepols  

- reires_<engine>.json:  
Engine specific properties to connect to the API  

- reires_<engine>_mapping.json:  
Mapping of indexes, sort-options, aggregation-terms between the engine and the ReIReS-model/properties  

- reires_<engine>_query_replacements.json:  
Search and replace a part of the retrieved search query before sending it to the API  

- reires_<engine>_datamodel.json (not necessary for ReIReS ES-index):  
Part of the datamodel that can be add to the retrieved records, to make them compatabel with the ReIReS-datamodel.  


# API request parameters
- POST /blend
   - q : querystring (index: term [operator] )
   - f : filter
   - s : sort option (relevance / publicationdate = date ASC / date DESC / title / author)
   - from : return results from number
   - step : number of results in 1 response
   - nav : navigation (first / next/ prev)
   - user : {ip,id,brepolsid}  
      Access controle to the Brepols API is based on user_ip, user_id and brepolstoken in combination with the API-key in ./config/reires_brepols.json. The search_blender API will pass the provided parameter to the Brepols API  
         -- config  - api_key =>  Brepols - ApiKey,  
         -- request - user["ip"] =>  Brepols - UserIP,   
         -- request - user["id"] =>  Brepols - UserID,  
         -- request - user["brepolsid"] => Brepols - UserToken,  
   - engines : hash of engines that have to be processed. It also includes parameters for each engine for navigation through the results list, and possible (error)-message   
   Parameters for each engine
      - timed_out : false / false,
      - took : time to process,
      - from : return results from number
      - total : total number of hits
      - size : array of integers that represents the number of results from this engine are in the returned resultslist for each step.
         This is also the reason that there is no page numbering. The pages must be built in order (first, next, previous).
      - message : message from the engine
 - POST /record
   - id => this is used to retrieve 1 specific records with this ID.

# API response parameters
The api response is an ElasticSearch-like response where the "default" parameters were supplemented with engines.
- timed_out : false / false, 
- took : time to process,
- hits : the results
- aggregations : 
- engines : hash of engines that have been processed. It also includes parameters for each engine for navigation through the results list, and possible (error)-message 

