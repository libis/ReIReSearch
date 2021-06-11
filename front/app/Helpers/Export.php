<?php
namespace App\Helpers;
use GuzzleHttp\Client as Client;
use App\Mail\Mail as Email;
use Illuminate\Support\Facades\Mail;
use App\Queue;
use App\Eshelf;

class Export {
    private $queue;

    private $mailbody = "Your export from ReIReSearch is ready. You can now download it.<br><br>1) Log on to https://reiresearch.eu (if you are not logged in yet)<br><br>2) Next click the following hyperlink : {url}<br><br><br>This hyperlink will remain valid for 10 days.";

    public function __construct() {
        $this->queue = Queue::where("status",0)->orderBy('created_at','ASC')->first();
    }    

    public function exec() {
        if ($this->queue) {
            // set job state : processing
            $this->queue->status = 1;
            $this->queue->save();

            // get job
            $job = json_decode($this->queue->job);

           
            // select output channel based on format
            switch($job->format) {
                case 'json':
                case 'jsonld';
                    $output = new JSON_Output();
                break;
                case 'csv';
                    $output = new CSV_Output();
                break;
            }

            if ($job->querytype == "set") {
                $set = Eshelf::find($job->set)->items()->get();
                foreach ($set as $k => $v) {
                    $tmp = json_decode($v->value);
                    unset($tmp->_display);
                    $data[] = $tmp;
                }
                $output->add($data);
            } else { 
                // setup interface with searchengine
                $searcher = new Searcher($job, $this->queue->user_id);

                // get first set ofo data
                $data = $searcher->first();

                // loop while there is more data
                while ($data) {
                    $output->add($data);
                    $data = $searcher->next();
                }
            }
            // save output

            $id = $output->save();

            // mail with link to id

            $url = "https://reiresearch.eu/export/" . $id;
            $body = str_replace("{url}",$url, $this->mailbody);
            $subject = "ReIReSearch export " . $this->queue->created_at . " UTC";

            Mail::to($this->queue->email)->send(new Email($body,$subject));

            // set job state : complete
            $this->queue->status = 2;
            $this->queue->save();


        }
    }
}




?>