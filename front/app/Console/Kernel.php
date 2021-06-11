<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;
use App\Helpers\Export;
use App\Helpers\Sitemap;

class Kernel extends ConsoleKernel
{
    /**
     * The Artisan commands provided by your application.
     *
     * @var array
     */
    protected $commands = [
        //
    ];

    /**
     * Define the application's command schedule.
     *
     * @param  \Illuminate\Console\Scheduling\Schedule  $schedule
     * @return void
     */
    protected function schedule(Schedule $schedule)
    {
        // $schedule->command('inspire')
        //          ->hourly();

        $schedule->call(function() {
            $threshold = time() - (12*24*60*60); // files older than 12 days delete
            foreach (glob(storage_path('app/export')."/*") as $file) {
                if (filemtime($file) < $threshold) {
                    unlink($file);
                }
            }
        })->daily();

        $schedule->call(function() {
            $job = new Export();
            $job->exec();
        }); 
        
        $schedule->call(function() {
           $site = new Sitemap();
           $site->exec() ;
        })->weekly();
    }

    /**
     * Register the commands for the application.
     *
     * @return void
     */
    protected function commands()
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
