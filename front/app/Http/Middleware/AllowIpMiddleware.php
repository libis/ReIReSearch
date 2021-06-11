<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Support\Facades\Log;

class AllowIpMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
 
    public function handle($request, Closure $next)
    {

        if (config()['app']['env'] == "local" || !config()['app']['block_by_ip']) {
            return $next($request);
        }
        
        $client_ip = self::getUserIpAddr();

        $allowed_ip_ranges = config()['app']['allowed_ip_ranges'];
        
        if (filter_var($client_ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
            $client_ip = str_replace(array("[","]"),"", $client_ip); // [] characters need to be removed
            if ($this->ip_in_ranges($client_ip,$allowed_ip_ranges['IPv6'],6, 128,":",16)) {
                return $next($request);
            }
        }
        if (filter_var($client_ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
            if ($this->ip_in_ranges($client_ip,$allowed_ip_ranges['IPv4'],4 ,32,".",8)) {
                return $next($request);
            }
        }
        
        Log::notice('Access denied to IP : ' . $client_ip);
        abort(403,"I'm afraid you are not allowed in " . $client_ip);
    }


    private function ip_in_ranges($ip, $ranges, $version) {

        switch ($version) {
            case 4:
                $len = 32;
                $lim = ".";
                $ellen = 8;
            break;
            case 6:
                $len = 128;
                $lim = ":";
                $ellen = 16;
            break;
            default:
                return False;
            break;
        }
        $ip = inet_pton($ip);
        foreach ($ranges as $range) {
            $t = array();

            if (strpos($range, '/') !== false) {
                $r = explode("/", $range);
                $binmask = str_repeat("1",$r[1]) . str_repeat("0",$len-$r[1]);
                for ($i=0;$i<$len;$i+=$ellen) {
                    if ($version == 6) $t[] = dechex(bindec(substr($binmask,$i,$ellen)));
                    if ($version == 4) $t[] = bindec(substr($binmask,$i,$ellen));
                }
                $netmask = implode($lim,$t);

                $lowend = inet_pton($r[0]) & inet_pton($netmask);
                $highend = inet_pton($r[0]) | ~ inet_pton($netmask);
            } else {
                if (strpos($range, '-') !== false) {
                    $r = explode("-", $range);
                    $lowend = inet_pton($r[0]);
                    $highend = inet_pton($r[1]);
                } else {
                    $lowend = inet_pton($range);
                    $highend = inet_pton($range);
                }
            }


            if ($lowend <= $ip && $ip <= $highend) {
                return True;
            }
        }
        return False;
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
