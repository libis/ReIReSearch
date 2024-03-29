<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Helpers\Sitemap;

class SitemapRefresh extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'sitemap:refresh';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Updates the sitemap';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle()
    {
        //
        $site = new Sitemap();
        $site->exec() ;
    }
}
