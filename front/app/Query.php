<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Query extends Model
{

    public function user() {
        return $this->belongsTo(User::class);
    }
}
