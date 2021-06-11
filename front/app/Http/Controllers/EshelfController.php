<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;


class EshelfController extends Controller
{

    public function __construct()
    {
        $this->middleware('auth');
    }

    public function list() {
        $user = Auth::User();
        
        $eshelves = $user->load('eshelfs.items')->eshelfs->toArray();
        foreach($eshelves as $k=>$shelf) {
            foreach($shelf['items'] as $l=>$item) {
                $eshelves[$k]['items'][$l]['value'] = json_decode($item['value']);
            }
        }

        return $eshelves;
    }

    public function store(Request $request) {
        $user = Auth::User();

        $data = json_decode($request->getContent(), true);

        $shelf = \App\Eshelf::where("name", $data["shelf"])->where("user_id", $user->id)->get();

        if ($shelf->isEmpty()) {
            $shelf = new \App\Eshelf;
            $shelf->name = $data["shelf"];
            $shelf->user_id = $user->id;
            $shelf->save();
        }
        $shelf = \App\Eshelf::where("name", $data["shelf"])->where("user_id", $user->id)->first();


        if (isset($data["values"])) {
            foreach ($data["values"] as $value) {
                $item = new \App\Item;
                $item->eshelf_id = $shelf->id;
                $item->value = json_encode($value);
                $item->save();
            }
        } else {
            $item = new \App\Item;
            $item->eshelf_id = $shelf->id;
            $item->value = json_encode($data["value"]);
            $item->save();
        }

        return "";
    }


    public function itemdelete($id) {
        $user = Auth::User();
        $item = \App\Item::where('id',$id)->first();
        $shelf = \App\Eshelf::where('id',$item->eshelf_id)->where('user_id',$user->id)->first();
        if ($shelf) {
            $item->delete();
        }
        return "";
    }

    public function delete($id) {
        $user = Auth::User();
        $shelf = \App\Eshelf::where('id',$id)->where('user_id',$user->id)->first();

        if ($shelf) {
            $deletedItems = \App\Item::where('eshelf_id', $id)->delete();
            $shelf->delete();
        }
        return "";
    }
}
