<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Queue extends Model
{
    //

    protected $hidden = ['user_id'];

    protected $table = "queue";
    
    public function user() {
        return $this->belongsTo(User::class);
    }

}
