<?php
namespace App\Helpers;
use GuzzleHttp\Client as Client;
use Illuminate\Support\Facades\Log;

class Sitemap {
    public function __construct() {
        $this->url=config('app.elastic_url');
        $this->esquery = json_decode('{
            "query": {
              "match_all": {}
            },
            "size":500
          }');


    }    

    public function exec() {
        $data = $this->first();
        
        // temporary storage leegmaken
        $files = glob(storage_path('app/tmp')."/*"); // get all file names
        foreach($files as $file){ // iterate files
        if(is_file($file))
            echo "Deleteing " . $file . "\n";
            unlink($file); // delete file
        }

        $subfiles = [];
        $refs = [];

        // loop while there is more data
        while ($data) {
            foreach($data as $k => $v) {
                $refs[]=Array("loc"=>$v->_source->url,"lastmod"=>$v->_source->sdDatePublished);
            }
            sleep(1);
            if (count($refs) == 50000) {
                $subfiles[] = $this->makexmlfile($refs);
                $refs = [];
            }
            $data = $this->next();
        }

        if (count($refs) > 0) {
            $subfiles[] = $this->makexmlfile($refs);
        }


        $fp = fopen(storage_path('app/tmp') . '/sitemap.xml', "w");
        fwrite($fp, "<?xml version=\"1.0\"?><sitemapindex xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">");
        foreach($subfiles as $url) {
            fwrite($fp, "<sitemap><loc>" . $url . "</loc></sitemap>");
        }
        fwrite($fp, "</sitemapindex>");
        fclose($fp);


        // public storage leegmaken
        $files = glob(public_path('sitemap/')."*"); // get all file names
        foreach($files as $file){ // iterate files
        if(is_file($file))
            echo "Deleteing " . $file . "\n";
            unlink($file); // delete file
        }

        // files van temp storage overkopieren naar public storage

        $files = glob(storage_path('app/tmp')."/*"); // get all file names
        foreach($files as $file){ // iterate files
        if(is_file($file))
            echo "Moving " . $file . "\n";
            $src = $file;
            $dst = public_path('sitemap/') . basename($file);
            rename($src, $dst);
        }
    }


    private function makexmlfile($chunk) {
        $filename = trim(file_get_contents('/proc/sys/kernel/random/uuid')) . ".xml.gz";
        $fp = fopen(storage_path('app/tmp') . "/" . $filename, "w");
        $xml = '<?xml version="1.0"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">';
        foreach($chunk as $p) {
            $xml .= '<url>';
            $xml .= '<loc>' . $p["loc"] . '</loc>';
            $xml .= '<lastmod>' . $p["lastmod"] . '</lastmod>';
            $xml .= '</url>';
        }
        $xml .= "</urlset>";
        fwrite($fp, gzencode($xml,9));
        fclose($fp);
        return "https://reiresearch.eu/sitemap/".$filename;
    }

    private function first() {
        $client = new Client();
        Log::info(print_r($this->esquery, True));
        $response = $client->request(   'POST', 
                                        $this->url . "&scroll=3000s", 
                                        [
                                            'body' => json_encode($this->esquery), 
                                            'headers' => [
                                                'Content-Type' => 'application/json'
                                            ], 
                                            'verify' => false
                                        ]
                                    );
        
        $r = json_decode($response->getBody()->getContents());
        $this->_scroll_id = $r->_scroll_id;

        if (count($r->hits->hits) > 0) {
            return $r->hits->hits;
        } else {
            return False;        
        }

    }

    private function next() {
        $client = new Client();
        $p = parse_url($this->url);
        $query = (object)["scroll" => "3000s", "scroll_id" => $this->_scroll_id];
        Log::info(print_r($query, True));
        $response = $client->request(   'POST', 
                                        $p["scheme"] . "://" . $p["host"] . ":" . $p["port"]  . "/_search/scroll", 
                                        [
                                            'body' => json_encode($query), 
                                            'headers' => [
                                                'Content-Type' => 'application/json'
                                            ], 
                                            'verify' => false
                                        ]
                                    );
        $r = json_decode($response->getBody()->getContents());
        $this->_scroll_id = $r->_scroll_id;
        if (count($r->hits->hits) > 0) {
            return $r->hits->hits;
        } else {
            return False;        
        }
    }

}




?>