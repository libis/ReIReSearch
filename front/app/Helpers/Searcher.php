<?
namespace App\Helpers;
use GuzzleHttp\Client as Client;
use Illuminate\Support\Facades\Log;
use App\User;

class Searcher {

    private $query = "";
    private $url = "";
    private $step = 100;
    private $from = 0;
    private $engines = [];
    private $nav = 'first';

    public function __construct($query = Null, $user_id = 0) {
        $this->url = config('app.search_url');
        $this->query = $query;
        $this->user_id = $user_id;
        
    }

    public function first() {
        $this->from = 0;
        $this->nav = "first";
        $this->step = 100;
        print_r($this->query);

        $this->engines = [];

        foreach($this->query->sources as $source) {
            $this->engines[$source] = (object) null;
        }

        return $this->next();
    }

    public function next() {
        
        $searchstate = ["from" => $this->from, "step" => $this->step, "engines" => $this->engines ] ;
        $requestbody = array_merge($searchstate, (array)$this->query);

        $requestbody["nav"] = $this->nav;

        unset($requestbody["sources"]);
        unset($requestbody["format"]);
        unset($requestbody["querytype"]);

        $client = new Client();

        Log::info(json_encode($requestbody));
        print_r($requestbody);
        $result = $client->request('POST', $this->url, ['json' => $requestbody]);

        $statuscode = $result->getStatusCode();

        if ($statuscode != 200) {

            return False;

        } else {
            $resultbody = json_decode($result->getBody()); 
             
            if (count($resultbody->hits->hits) > 0) {
                $this->engines = $resultbody->engines;
                $this->from = $resultbody->hits->from;
                $this->step = $resultbody->hits->step;
                $this->nav = "next";
                return $resultbody->hits->hits;
            } else {
                return False;        
            }
        }
    }
}


?>