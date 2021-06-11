<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use GuzzleHttp\Client as Client;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class SearchController extends Controller
{
    //

    private $url = "";
    private $recordurl = "";

    public function __construct() {

        $this->url = config('app.search_url');
        $this->recordurl = config('app.record_url');
    
        $this->iso639 = array();
        foreach(json_decode(file_get_contents(resource_path("json/iso639.json")),True) as $v) {
            $this->iso639[$v["alpha3-b"]] = $v["English"];
        }
    }

    public function search(Request $request) {
        $querybody = json_decode($request->getContent(), true);

        $engines = [];
        
        foreach($querybody["sources"] as $source) {
            $engines[$source] = (object) null;
        }
        
        if ($querybody["nav"] == 'first') {
            $searchstate = ["from" => 0, "step" => 20, "engines" => $engines ] ;
            
            if ($request->session()->has('history')) {
                $history = $request->session()->get('history');
            } else {
                $history = Array();
            }
            $history[] = array_merge($querybody, ["created"=>date("Y-m-d\TH:i\Z", time())]);
            
            $request->session()->put('history', $history);

        } else {
            $searchstate = $request->session()->get('searchstate');
        }

        $requestbody = array_merge($searchstate, $querybody);

        $requestbody["user"] = Array();
        
        if (Auth::check()) {
            // The user is logged in...
            // hier eventueel bijkomende (user)info in request steken
            $user = Auth::user();
            if ($user["brepolsid"] == Null) {
                $requestbody["user"]["brepolsid"] = "";
                $requestbody["user"]["id"] = "";
            } else {
                $requestbody["user"]["brepolsid"] = $user["brepolsid"];
                $requestbody["user"]["id"] = $user["name"];
            }
        } 
    
        $requestbody["user"]["ip"] = self::getUserIpAddr();

        $client = new Client();

        Log::info(json_encode($requestbody));

        if (trim($requestbody["q"]) != "") {

            $result = $client->request('POST', $this->url, ['json' => $requestbody]);

            $statuscode = $result->getStatusCode();

            if ($statuscode != 200) {

                abort($statuscode,$result->getReasonPhrase());

            } else {

                $resultbody = json_decode($result->getBody()); 

                foreach ($resultbody->hits->hits as $k => $hit) {
                    $resultbody->hits->hits[$k]->_display = $this->display($hit);
                }

                $searchstate = ['engines' => $resultbody->engines, 'from'=>$resultbody->hits->from,'step'=>$resultbody->hits->step];
                $request->session()->put("searchstate", $searchstate);

                if (isset($resultbody->aggregations->inLanguage)) {
                    foreach ($resultbody->aggregations->inLanguage->buckets as $k => $v) {
                        if (isset($this->iso639[$v->key])) {
                            $resultbody->aggregations->inLanguage->buckets[$k]->key_as_string = $this->iso639[$v->key];
                            $resultbody->aggregations->inLanguage->buckets[$k]->cbvalue = "inLanguage:\"" . $v->key . "\"";
                        } else {
                            unset($resultbody->aggregations->inLanguage->buckets[$k]);
                        }
                    }
                } 

                unset($resultbody->aggregations->datePublished);        
                unset($resultbody->aggregations->dateCreated);   
                unset($resultbody->aggregations->sdDatePublished);   
                unset($resultbody->aggregations->digitalrepresentation);   

                $sorted_aggregations = $this->sort_aggregations($resultbody->aggregations);
                
                $sorted_aggregations->digitalrepresentation = (object) Array();
                $sorted_aggregations->digitalrepresentation->buckets = Array(
                    Array("cbvalue"=>"digitalrepresentation:true", "key_as_string"=>"Present")
                );

                $today = date("Y-m-d");
                $week1 = date("Y-m-d", strtotime('-1 week'));
                $week2 = date("Y-m-d", strtotime('-2 week'));
                $month1 = date("Y-m-d", strtotime('-1 month'));
                $month3 = date("Y-m-d", strtotime('-3 month'));
                $month6 = date("Y-m-d", strtotime('-6 month'));
                $year1 = date("Y-m-d", strtotime('-1 year'));

                

                $sorted_aggregations->sdDatePublished = (object) Array();
                $sorted_aggregations->sdDatePublished->buckets=Array(
                    Array("cbvalue"=>"sdDatePublished:[" . $week1 . " TO " . $today . "]", "key_as_string"=>"Last week"),
                    Array("cbvalue"=>"sdDatePublished:[" . $week2 . " TO " . $today . "]", "key_as_string"=>"Last 2 weeks"),
                    Array("cbvalue"=>"sdDatePublished:[" . $month1 . " TO " . $today . "]", "key_as_string"=>"Last month"),
                    Array("cbvalue"=>"sdDatePublished:[" . $month3 . " TO " . $today . "]", "key_as_string"=>"Last 3 months"),
                    Array("cbvalue"=>"sdDatePublished:[" . $month6 . " TO " . $today . "]", "key_as_string"=>"Last 6 months"),
                    Array("cbvalue"=>"sdDatePublished:[" . $year1 . " TO " . $today . "]", "key_as_string"=>"Last year"),
                );

                

                return response()->json(["hits" => $resultbody->hits->hits, 
                        "aggregations" => $sorted_aggregations, 
                        "engines" => $resultbody->engines, 
                        "took" => $resultbody->took, 
                        "timed_out" => $resultbody->timed_out, 
                        "total" => $resultbody->hits->total,
                        "search_total" => $resultbody->hits->search_total,
                        "history" => $request->session()->get('history')
//                        "request" => $requestbody 
                    ],200,[], JSON_UNESCAPED_SLASHES);
            }
        } else {

            abort(400, "Please enter a searchterm");

            return ["hits" => [],
            "aggregations" => [],
            "engines" => $searchstate['engines'], 
            "took" => 0,
            "timed_out" => false, 
            "total" => 0
        ];

        }
    }

    public function record($id, $format = null) {
 
        $requestbody = array("id"=>$id);

        $requestbody["user"] = Array();
        
        if (Auth::check()) {
            // The user is logged in...
            // hier eventueel bijkomende (user)info in request steken
            $user = Auth::user();
            if ($user["brepolsid"] == Null) {
                $requestbody["user"]["brepolsid"] = "";
                $requestbody["user"]["id"] = "";
            } else {
                $requestbody["user"]["brepolsid"] = $user["brepolsid"];
                $requestbody["user"]["id"] = $user["name"];
            }
        }         

        $requestbody["user"]["ip"] = self::getUserIpAddr();

        Log::info(json_encode($requestbody));

        $client = new Client();

        $result = $client->request('POST', $this->recordurl, ['json' => $requestbody,'http_errors' => false]);

        $statuscode = $result->getStatusCode();

        if ($statuscode != 200) {
            abort($statuscode,$result->getReasonPhrase());
        } else {
            $resultbody = json_decode($result->getBody()); 
            if (isset($resultbody->_source) && isset(((array)$resultbody->_source)["@id"])) {
                $record = $this->display($resultbody);
            } else {
                abort(404, "Requested document not found");
            }
        }
        $format = strtolower($format);
        switch ($format) {
            case 'json':
                return response()->json((array)$resultbody->_source,200,[], JSON_UNESCAPED_SLASHES);
                break;
            default:
                return view('record', array("source" => $resultbody->_source, "record" => $record));
                break;
        }
    }

    private function display($hit) {
        
        $display = Array();
                    
        $display["id"] = ((array)$hit->_source)["@id"];
        $display["type"] = ((array)$hit->_source)["@type"];
        if (isset($hit->_source->keywords)) $display["keywords"] = $this->process($hit->_source->keywords);
        if (isset($hit->_source->name)) $display["name"] = $this->process($hit->_source->name);
        if (isset($hit->_source->alternateName)) $display["alternateName"] = $this->process($hit->_source->alternateName);
        if (isset($hit->_source->author)) $display["author"] = $this->process($hit->_source->author); 
        if (isset($hit->_source->creator)) $display["creator"] = $this->process($hit->_source->creator); 
        if (isset($hit->_source->editor)) $display["editor"] = $this->process($hit->_source->editor); 
        if (isset($hit->_source->contributor)) $display["contributor"] = $this->process($hit->_source->contributor); 
        if (isset($hit->_source->illustrator)) $display["illustrator"] = $this->process($hit->_source->illustrator); 
        if (isset($hit->_source->translator)) $display["translator"] = $this->process($hit->_source->translator); 
        if (isset($hit->_source->description)) $display["description"] = $this->process($hit->_source->description);
        if (isset($hit->_source->url)) {
            $display["url"] = $this->process($hit->_source->url);
            foreach( $display["url"] as $k => $u) {
                $display["url"][$k] = str_replace('reires.libis.be', 'reiresearch.eu',$u);
                $display["url"][$k] = str_replace('reiresearch.reires.eu', 'reiresearch.eu',$u);
            }
        }
        if (isset($hit->_source->datePublished)) {
            $display["datePublished"] = $this->process($hit->_source->datePublished);
            foreach($display["datePublished"] as $k => $v) {
                if (preg_match('/([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}:[0-9]{2}:[0-9]{2})/', $v, $matches)) {
                    $display["datePublished"][$k] = $matches[1];
                }
            } 
        }

        if (isset($hit->_source->dateCreated)) $display["dateCreated"] = $this->process($hit->_source->dateCreated);
        if (isset($hit->_source->isBasedOn->license)) $display["license"] = $this->process($hit->_source->isBasedOn->license);
        if (isset($hit->_source->isBasedOn->provider)) {
            $display["provider"] = $this->process($hit->_source->isBasedOn->provider);
        } else {
            if (isset($hit->_source->provider)) {
                $display["provider"] = $this->process($hit->_source->provider);
            }
        }

        if (isset($hit->_source->isBasedOn->isPartOf)){
            if (is_array($hit->_source->isBasedOn->isPartOf)) {
                $display["DataSet"] = [];
                foreach($hit->_source->isBasedOn->isPartOf as $p) {
                    $display["DataSet"][] = $p;
                }
            } else {
                $display["DataSet"] = $this->process($hit->_source->isBasedOn->isPartOf);
            }
        }

        if (isset($hit->_source->locationCreated)) $display["locationCreated"] = $this->process($hit->_source->locationCreated);
        if (isset($hit->_source->publisher)) $display["publisher"] = $this->process($hit->_source->publisher);
        if (isset($hit->_source->sdDatePublished)) $display["sdDatePublished"] = $this->process($hit->_source->sdDatePublished);
        if (isset($hit->_source->sdPublisher)) $display["sdPublisher"] = $this->process($hit->_source->sdPublisher);
        if (isset($hit->_source->sdLicense)) $display["sdLicense"] = $this->process($hit->_source->sdLicense);
        if (isset($hit->_source->isPartOf)) $display["isPartOf"] = $this->process($hit->_source->isPartOf);
        if (isset($hit->_source->hasPart)) $display["hasPart"] = $this->process($hit->_source->hasPart);
        if (isset($hit->_source->pagination)) {
            $display["pagination"] = $this->process($hit->_source->pagination);
        } else {
            if (isset($hit->_source->pageStart)) {
                $pagestart = $this->process($hit->_source->pageStart);
                $pageend = $this->process($hit->_source->pageEnd);
                $display["pagination"] = Array();
                foreach($pagestart as $k => $v) {
                    $display["pagination"][] = $v . " - " . $pageend[$k];
                }
            }
        }
        if (isset($hit->_source->numberOfPages)) $display["numberOfPages"] = $this->process($hit->_source->numberOfPages);

        if (isset($hit->_source->volumeNumber)) $display["volumeNumber"] = $this->process($hit->_source->volumeNumber);
        if (isset($hit->_source->issueNumber)) $display["issueNumber"] = $this->process($hit->_source->issueNumber);
        if (isset($hit->_source->inLanguage)) {
            $display["inLanguage"] = array();
            foreach($this->process($hit->_source->inLanguage) as $v) {
                if (isset($this->iso639[$v])) {
                    $display["inLanguage"][] = $this->iso639[$v];
                }
            }
        }
        if (isset($hit->_source->Genre)) $display["Genre"] = $this->process($hit->_source->Genre);
        if (isset($hit->_source->isbn)) $display["isbn"] = $this->process($hit->_source->isbn);
        if (isset($hit->_source->issn)) $display["issn"] = $this->process($hit->_source->issn);

        if (isset($hit->_source->includedInDataCatalog)) $display["includedInDataCatalog"] = $this->process($hit->_source->includedInDataCatalog);
        
        if (isset($hit->_source->startDate)) $display["startDate"] = $this->process($hit->_source->startDate);
        if (isset($hit->_source->endDate)) $display["endDate"] = $this->process($hit->_source->endDate);
        if (isset($hit->_source->additionalType)) $display["additionalType"] = $this->process($hit->_source->additionalType);

        if (isset($hit->_source->about)) $display["about"] = $this->process($hit->_source->about);
        if (isset($hit->_source->subjectOf)) $display["subjectOf"] = $this->process($hit->_source->subjectOf);
        if (isset($hit->_source->contentLocation)) $display["contentLocation"] = $this->process($hit->_source->contentLocation);
        if (isset($hit->_source->spatialCoverage)) $display["spatialCoverage"] = $this->process($hit->_source->spatialCoverage);
        if (isset($hit->_source->temporalCoverage)) $display["temporalCoverage"] = $this->process($hit->_source->temporalCoverage);

        if (isset($hit->_source->mentions)) $display["mentions"] = $this->process($hit->_source->mentions);
        if (isset($hit->_source->associatedMedia)) $display["associatedMedia"] = $this->process($hit->_source->associatedMedia);
        if (isset($hit->_source->distribution)) $display["distribution"] = $this->process($hit->_source->distribution);
        if (isset($hit->_source->copyrightHolder)) $copyrightHolder = $this->process($hit->_source->copyrightHolder);
        if (isset($hit->_source->copyrightYear)) $copyrightYear = $this->process($hit->_source->copyrightYear);
        if (isset($copyrightHolder)) {
            $display["copyright"] = Array();
            foreach($copyrightHolder as $k => $v) {
                $display["copyright"] = (isset($copyrightYear[$k])?$copyrightYear[$k]. " ":"") . $v;
            }
        }

        if (isset($hit->_source->bookEdition)) $display["bookEdition"] = $this->process($hit->_source->bookEdition);
        if (isset($hit->_source->material)) $display["material"] = $this->process($hit->_source->material);
        if (isset($hit->_source->review)) $display["review"] = $this->process($hit->_source->review);
        if (isset($hit->_source->itemReviewed)) $display["itemReviewed"] = $this->process($hit->_source->itemReviewed);

        if (isset($hit->_source->translationOfWork)) $display["translationOfWork"] = $this->process($hit->_source->translationOfWork);
        if (isset($hit->_source->workTranslation)) $display["workTranslation"] = $this->process($hit->_source->workTranslation);
        if (isset($hit->_source->version)) $display["version"] = $this->process($hit->_source->version);                    

        if (isset($hit->_source->thumbnailUrl)) {
            $display["thumbnailUrl"] = $this->process($hit->_source->thumbnailUrl);
        } else {
            if (isset($hit->_source->associatedMedia->thumbnailUrl)) {
                $display["thumbnailUrl"] = $this->process($hit->_source->associatedMedia->thumbnailUrl);
            }
        }

        $thumbnails = Array();
        if (isset($hit->_source->thumbnailUrl)) {
            $tmp = $this->process($hit->_source->thumbnailUrl);
            $same = $this->process($hit->_source->sameAs);
            foreach ($tmp as $k => $v) {
                if ($v!="") {
                    $thumb = Array("thumbnailUrl"=>$v, "url"=>$same[0]);
                    $thumbnails[] = $thumb;
                }
            }
        }
        if (isset($hit->_source->associatedMedia)) {
            $am = $this->process($hit->_source->associatedMedia);

            foreach ($am as $k => $v) {
                //Log::info($v);
                if (isset($v["thumbnailUrl"])) {
                    if ($v["thumbnailUrl"] != "") {
                        $thumb = Array("thumbnailUrl"=>$v["thumbnailUrl"]);
                        if (isset($v["contentUrl"])) {
                            $thumb["contentUrl"] = $v["contentUrl"];
                        }
                        if (isset($v["url"])) {
                            $thumb["url"] = $v["url"];
                        }
                        $thumbnails[] = $thumb;
                    }
                }
            }
        }

        if (isset($hit->_source->familyName)) $display["familyName"] = $this->process($hit->_source->familyName);                    
        if (isset($hit->_source->givenName)) $display["givenName"] = $this->process($hit->_source->givenName);                    
        if (isset($hit->_source->additionalName)) $display["additionalName"] = $this->process($hit->_source->additionalName);                    
        if (isset($hit->_source->honorificPrefix)) $display["honorificPrefix"] = $this->process($hit->_source->honorificPrefix);                    
        if (isset($hit->_source->honorificSuffix)) $display["honorificSuffix"] = $this->process($hit->_source->honorificSuffix);                    
        if (isset($hit->_source->affiliation)) $display["affiliation"] = $this->process($hit->_source->affiliation);                    
        if (isset($hit->_source->worksFor)) $display["worksFor"] = $this->process($hit->_source->worksFor);                    
        if (isset($hit->_source->hasOccupation)) $display["hasOccupation"] = $this->process($hit->_source->hasOccupation);                    
        if (isset($hit->_source->jobTitle)) $display["jobTitle"] = $this->process($hit->_source->jobTitle);                    
        if (isset($hit->_source->birthDate)) $display["birthDate"] = $this->process($hit->_source->birthDate);                    
        if (isset($hit->_source->birthPlace)) $display["birthPlace"] = $this->process($hit->_source->birthPlace);                    
        if (isset($hit->_source->deathDate)) $display["deathDate"] = $this->process($hit->_source->deathDate);                    
        if (isset($hit->_source->deathPlace)) $display["deathPlace"] = $this->process($hit->_source->deathPlace);                    
        if (isset($hit->_source->gender)) $display["gender"] = $this->process($hit->_source->gender);                    
        if (isset($hit->_source->nationality)) $display["nationality"] = $this->process($hit->_source->nationality);                    
        if (isset($hit->_source->parent)) $display["parent"] = $this->process($hit->_source->parent);                    
        if (isset($hit->_source->children)) $display["children"] = $this->process($hit->_source->children);                    
        if (isset($hit->_source->relatedTo)) $display["relatedTo"] = $this->process($hit->_source->relatedTo);                    
        if (isset($hit->_source->sibling)) $display["sibling"] = $this->process($hit->_source->sibling);                    
        if (isset($hit->_source->spouse)) $display["spouse"] = $this->process($hit->_source->spouse);                    
        if (isset($hit->_source->colleague)) $display["colleague"] = $this->process($hit->_source->colleague);                    
        if (isset($hit->_source->follows)) $display["follows"] = $this->process($hit->_source->follows);                    
        if (isset($hit->_source->knows)) $display["knows"] = $this->process($hit->_source->knows);                    
        if (isset($hit->_source->memberOf)) $display["memberOf"] = $this->process($hit->_source->memberOf);                    
        if (isset($hit->_source->funder)) $display["funder"] = $this->process($hit->_source->funder);                    
        if (isset($hit->_source->sponsor)) $display["sponsor"] = $this->process($hit->_source->sponsor);                    
        if (isset($hit->_source->alumniOf)) $display["alumniOf"] = $this->process($hit->_source->alumniOf);                    

        if (count($thumbnails) > 0) $display["thumbnails"] = $this->unique_thumbnails($thumbnails);

        if (isset($hit->_source->sameAs)) {
            $display["source"] = $this->process($hit->_source->sameAs);
        }

        if (isset($display["source"])) {
            for($i=count($display["source"])-1;$i>=0;$i--) {
                if(!filter_var($display["source"][$i], FILTER_VALIDATE_URL)) {
                    array_splice($display["source"],$i,1);
                }
            }
        }

        $display["citations"] = Array();

        return $display;
    }

    public function history(Request $request) {
        return $request->session()->get('history');
    }

    public function ddlists(Request $request) {
        $list = [];
        $client = new Client();
        $query = '{
            "query": {
                "match_all": {}
            },
            "size": 0,
            "aggregations":{
                "providers":{
                    "terms": {
                        "field":"isBasedOn.provider.name.keyword"
                    }
                },
                "datasets":{
                    "terms": {
                        "field":"isBasedOn.isPartOf.name.keyword"
                    }
                }
            }
        }';
        $response = $client->request(   'POST', 
                                        config('app.elastic_url'),
                                        [
                                            'body' => $query, 
                                            'headers' => [
                                                'Content-Type' => 'application/json'
                                            ], 
                                            'verify' => false
                                        ]
                                    );
        
        $r = json_decode($response->getBody()->getContents());

        $lists["datasets"] = [];
        foreach ($r->aggregations->datasets->buckets as $b) {
            $lists["datasets"][] = $b->key;
        }
        $lists["datasets"][] = "Index Religiosus";

        $lists["providers"] = [];
        foreach ($r->aggregations->providers->buckets as $b) {
            $lists["providers"][] = $b->key;
        }

        sort($lists["datasets"]);
        sort($lists["providers"]);

        return $lists;
    }

    private function process($data) {
#        Log::info(gettype($data));
#        Log::info(print_r($data,True));
#        Log::info("===============================================================================");
        switch(gettype($data)) {
            case "string":
            case "integer":                
                return array($data);
                break;
            case "array":
                $ret = Array();
                foreach($data as $k => $v) {
                    $ret = array_merge($ret, $this->process($v));
                }
                return $ret;
                break;
            case "object":
                $data = (array)$data;
                if (isset($data["@value"])) {
                    return array($data["@value"]);
                }
                if (isset($data["@type"])) {
                    switch ($data["@type"]) {
                        case "Organization":
                            if (isset($data["name"])) {
                                if (is_array($data["name"])) {
                                    $str = join(", ", $data["name"]);
                                } else {
                                    $str = $data["name"];
                                }
                                if (isset($data["location"])) {
                                    if (is_string($data["location"])) {
                                        $str .= ", " . $data["location"];
                                    }
                                    if (is_object($data["location"])) {
                                        $str .= ", " . ((array)$data["location"])["name"];
                                    }
                                }
                                return array($str);
                            } else {
                                return "";
                            }
                            break;
                        case "Role":
                            $str = "";

                            if (isset($data["startDate"])) {
                                $str .= $data["startDate"];
                            }
                            if (isset($data["endDate"])) {
                                $str .= " - " . $data["endDate"];
                            }
                            if (isset($data["roleName"])) {
                                $str .= " " . $data["roleName"];
                            }
                            if (isset($data["memberOf"])) {
                                if (isset(((array)$data["memberOf"])["name"])){
                                    $str .= " " . ((array)$data["memberOf"])["name"];
                                }
                                if (isset(((array)$data["memberOf"])["location"]) && isset(((array)((array)$data["memberOf"])["location"])["name"])){
                                    $str .= " " . ((array)((array)$data["memberOf"])["location"])["name"];
                                }
                            }
                            return array($str);
                            break;
                        case "Person":
                            $str = "";
                            if (isset($data["name"]) && isset(((array)$data["name"])["@value"])) {
                                $str = ((array)$data["name"])["@value"];
                            } else {
                                $str = $data["name"];
                            }
                            return array($str);
                            break;
                        case "Place":
                            $str = "";
                            if (isset($data["name"]) && isset(((array)$data["name"])["@value"])) {
                                $str = ((array)$data["name"])["@value"];
                            } else {
                                $str = $data["name"];
                            }
                            return array($str);
                            break;                            
                        default:
                            $name = $url = $thumbnailurl = $location = "";
                            if (isset($data["name"]) && isset(((array)$data["name"])["@value"])) {
                                $name = ((array)$data["name"])["@value"];
                            } else {
                                if (is_array($data["name"])) {
                                    foreach($data["name"] as $n) {
                                        $name .= ((array)$n)["@value"] . " ";
                                    }
                                } else {
                                    $name = $data["name"];
                                }
                            }

                            if (isset($data["url"])) {
                                $url = $data["url"];
                            }

                            if (isset($data["contentUrl"])) {
                                $contenturl = $data["contentUrl"];
                            } else {
                                $contenturl = "";
                            }

                            if (isset($data["thumbnailUrl"])) {
                                $thumbnailurl = $data["thumbnailUrl"];
                            }

                            if (isset($data["location"])) {
                                $location = $data["location"];
                            }


                            if ($name == "" && $url != "") {
                                $name = $url;
                            }



                            $ret = Array();
                            if ($name != "") $ret["name"] = $name;
                            if ($location != "") $ret["location"] = $location;
                            if ($url != "") $ret["url"] = $url;
                            if ($thumbnailurl != "") $ret["thumbnailUrl"] = $thumbnailurl;
                            if ($contenturl != "") $ret["contentUrl"] = $contenturl;

                            return array($ret);
                            break;
                    }
                }
                break;
        }
    }

    private function sort_aggregations($agg) {
        foreach ($agg as $k_facet => $facet) {
            $facet = $this->sort_facet($facet);
        }
        return $agg;
    }

    private function sort_facet($fac) {
        return usort($fac->buckets,array($this,"mysort"));
    }

    private function mysort($a,$b) {

        if ($a->doc_count == $b->doc_count){
            if (isset($a->key_as_string) && isset($b->key_as_string)) {
                return ($a->key_as_string > $b->key_as_string);
            } else {
                return ($a->key > $b->key);
            }
        } else {
            return $a->doc_count < $b->doc_count;
        }
    }

    public function getUserIpAddr(){
        $ipaddress = '';
        if (isset($_SERVER['HTTP_CLIENT_IP']))
            $ipaddress = $_SERVER['HTTP_CLIENT_IP'];
        else if(isset($_SERVER['HTTP_X_LB_FORWARDED_FOR']))
            $ipaddress = $_SERVER['HTTP_X_LB_FORWARDED_FOR'];
        else if(isset($_SERVER['HTTP_X_FORWARDED']))
            $ipaddress = $_SERVER['HTTP_X_FORWARDED'];
        else if(isset($_SERVER['HTTP_FORWARDED_FOR']))
            $ipaddress = $_SERVER['HTTP_FORWARDED_FOR'];
        else if(isset($_SERVER['HTTP_FORWARDED']))
            $ipaddress = $_SERVER['HTTP_FORWARDED'];
        else if(isset($_SERVER['REMOTE_ADDR']))
            $ipaddress = $_SERVER['REMOTE_ADDR'];
        else
            $ipaddress = 'UNKNOWN';    
        return $ipaddress;
    }

    private function unique_thumbnails($tn) {
        $out = Array();

        foreach($tn as $t) {
            $out[] = $t;
            for($i=0; $i<count($out)-1; $i++){ 
                if ($out[$i]["thumbnailUrl"] == $t["thumbnailUrl"]) {
                    array_pop($out);
                }
            }
        }
        return $out;
    }


}