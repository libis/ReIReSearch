<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Mail\Mail as Email;
use Illuminate\Support\Facades\Mail;

class MailController extends Controller
{
    //
    public function email_item() {
        $fields = Array("author"=>"Author(s)", "contributor"=>"Contributor(s)", "description"=>"Description", "keywords"=>"Subject(s)");
        $data = json_decode(request()->getContent(), true);

        $to = $data["to"];
        $subject = $data["subject"];
        $mess = $data["message"];
        $body = ""; // "<pre>" . print_r($data["item"], true) . "</pre>";
        
        $item = $data["item"];
        if (isset($item["name"])) {
            foreach($item["name"] as $t) {
                $body .= "<a href='" . $item["url"][0] . "'>" . $t . "</a><br />\n";
            }
        } else {
            $body .= "<a href='" . $item["url"][0] . "'>" . $item["url"][0] . "</a><br />\n";
   
        }
         
        $body .= "<br /><ul>";


        foreach($fields as $k => $v) {
            if (isset($item[$k])) {
                $body .= "<li>" . $v . "</li>";
                $body .= "<ul>";
                foreach($item[$k] as $a) {
                    $body.= "<li>" . $a . "</li>";
                }
                $body .= "</ul>";
            }
        }
        $body .= "</ul><br /><br />";

        $body .= nl2br($mess);

        Mail::to($to)->send(new Email($body,$subject));
    }
}
