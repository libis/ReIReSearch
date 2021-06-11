<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Item extends Model
{
    //

    public function eshelf() {
        return $this->belongsTo(Eshelf::class);
    }
}
