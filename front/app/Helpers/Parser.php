<?php
namespace App\Helpers;
use Illuminate\Support\Facades\Log;


function swap(&$a,&$b) {
    $t = $a;
    $a = $b;
    $b = $t;
}

class Leaf {

    private $field;
    private $query;
    public $type;

    public function __construct($field,$query) {
        $this->field = $field;
        $this->query = $query;
        $this->type = "LEAF";
    }

    public function generateQuery() {
        $q = (object)[];
        $q->query_string = (object)[];
        $q->query_string->fields = $this->field;
        $q->query_string->query = $this->query;

        return $q;
    }
  
}

class Operator {
    public $type;
    public $left;
    public $right;

    public function __construct($type,$left,$right=null) {
        $this->type= $type;
        $this->left = $left;
        $this->right = $right;
    }

    public function generateQuery() {
        $q = (object)[];
        $q->bool = (object)[];

        switch ($this->type) {
            case "OR":
                $q->bool->should = [$this->left->generateQuery(),$this->right->generateQuery()];
            break;
            case "AND":
                $q->bool->must = [$this->left->generateQuery(),$this->right->generateQuery()];
            break;
            case "NOT":
                $q->bool->must_not = $this->left->generateQuery();
            break;
        }
        return $q;
    }

}


class Parser {

    private $q;
    public function __construct($q) {
        $this->q = $q;
    }

    public function generateQuery($prior=True) {
        $expr = new Leaf($this->q[0]->field,$this->q[0]->query);
        for ($i = 1; $i < count($this->q); $i++) {
            $type = $this->q[$i]->operator;
            $leaf = new Leaf($this->q[$i]->field,$this->q[$i]->query);
            if ($type == "NOT") {
                $expr = new Operator("AND", $expr, (new Operator($type, $leaf)));
            } else {
                $expr = new Operator($type, $expr, $leaf);
            }
        }
        if ($prior) {
            $this->prioritize($expr);
        }
        return $expr->generateQuery();;
    }
    
    private function prioritize(&$tree) {

        if ($tree->type != "LEAF") {
            if ($tree->type == "AND" && $tree->left->type == "OR") {
                swap($tree->left->left, $tree->right);
                swap($tree->left->type, $tree->type);
            }
        
            if ($tree->type == "AND" && $tree->right->type == "OR") {
                swap($tree->right->left, $tree->left);
                swap($tree->right->type, $tree->type);
            }
        
        
            if ($tree->left->type != "LEAF") {
                $this->prioritize($tree->left);
            }
            if ($tree->right->type != "LEAF") {
                $this->prioritize($tree->right);
            }
        }
    }

}

