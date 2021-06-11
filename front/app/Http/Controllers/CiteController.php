<?php

namespace App\Http\Controllers;
use GuzzleHttp\Client as Client;
use Illuminate\Http\Request;

class CiteController extends Controller
{
    //

    private $url = 'https://reires.libis.be/cite/';

    public function cite(Request $request, $style, $format, $mode) {

        $body = json_decode($request->getContent());

        $url = $this->url . $style . "/" . $format . "/" . $mode;

        $client = new Client();

        $result = $client->post($url, 
            ['body' => json_encode($body),
            'headers' => [
                'content-type' => $request->header("Content-Type")
            ]]
        );

        $statuscode = $result->getStatusCode();

        if ($statuscode != 200) {

            abort($statuscode,$result->getReasonPhrase());

        } else {

            return $result->getBody(); 
        }
    }
}
