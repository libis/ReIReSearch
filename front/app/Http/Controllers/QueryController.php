<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use App\Query;
use App\Queue;

class QueryController extends Controller
{
    //
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function save(Request $request) {
        $user = Auth::User();
        $queryobj = $request->getContent();
        $querybody = json_decode($queryobj, true);
        $query = new Query;
        $query->user_id = $user->id;
        $query->querystring = $querybody["q"];
        $query->query = $queryobj;

        $query->save();

        return  $this->list($request);
    }


    public function list(Request $request) {
        $user = Auth::User();
        
        $list = \App\Query::where('user_id', $user->id)->orderBy('created_at', 'DESC')->get();

        foreach ($list as $k => $v) {
            $list[$k]["created"] = gmdate('Y-m-d\TH:i\Z', strtotime($v["created_at"]));
        }

        return $list;
    }

    public function delete(Request $request) {
        $user = Auth::User();
        $query = \App\Query::where('user_id', $user->id)->where('id', $request->id)->delete();
    }

    public function queue(Request $request) {
        $user = Auth::User();
        $obj = json_decode($request->getContent());
       
        $obj->user = Array();
        $obj->user["brepolsid"] = $user->brepolsid;
        $obj->user["id"] = $user->name;
        $obj->user["ip"] = self::getUserIpAddr();

        if (isset($user->email) && $user->email != "") {
            $queue = new Queue;
            $queue->user_id = $user->id;
            $queue->job = json_encode($obj);
            $queue->email = $user->email;
            $queue->save();
            return $queue;
        }
        abort(500);
    }

    public function download(Request $request, $id) {
        $user = Auth::User();
        $filename = $id . ".zip";
        return Storage::download('export/'.$filename, "export.zip");
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

}
