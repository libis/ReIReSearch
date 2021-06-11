<?
namespace App\Helpers;

class JSON_Output {

    public function __construct() {
        $this->tmpname = tempnam(storage_path('app/export'),'');
        $this->fhandle = fopen($this->tmpname, 'w');
        $this->first = True;
    }
    
    public function add($data) {
        foreach($data as $d) {
            if ($this->first) {
                fwrite($this->fhandle, "[\n");
                $this->first = False;
            } else {
                fwrite($this->fhandle, ",\n");
            }
            fwrite($this->fhandle,json_encode($d, JSON_PRETTY_PRINT+JSON_UNESCAPED_SLASHES));
        }
    }
    
    public function save() {
        fwrite($this->fhandle, "\n]");
        fclose($this->fhandle);
        rename($this->tmpname, $this->tmpname.".jsonld");
        $cmd = "zip -m -j " . $this->tmpname . ".zip " . $this->tmpname . ".jsonld";
        exec($cmd);
        return basename($this->tmpname);
    }
}
    