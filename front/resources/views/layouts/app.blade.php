<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <!-- Google Tag Manager -->
    <script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
    new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
    j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
    'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
    })(window,document,'script','dataLayer','GTM-TP3VQZC');</script>
    <!-- End Google Tag Manager -->
    <!-- Global site tag (gtag.js) - Google Analytics -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=UA-158184314-1"></script>
    <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());

    gtag('config', 'UA-158184314-1');
    </script>        
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <!-- CSRF Token -->
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ config('app.name', 'Laravel') }}</title>
    <link href="https://fonts.googleapis.com/css?family=Monda:700|Open+Sans:300,300i,600" rel="stylesheet">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
<!--    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bulma/0.7.5/css/bulma.min.css"> -->
    <link href="{{ asset('css/mystyles.css') }}" rel="stylesheet">
    <link href="{{ asset('css/stylesheet.css') }}" rel="stylesheet">
    
</head>
<body>
    <!-- Google Tag Manager (noscript) -->
    <noscript><iframe src="https://www.googletagmanager.com/ns.html?id=GTM-TP3VQZC"
    height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
    <!-- End Google Tag Manager (noscript) -->
    <div class="container">
        <div class="block">
        <nav class="navbar" role="navigation" aria-label="main navigation">
            <div class="navbar-brand">
            <a href="{{ url('/') }}"><img src="/img/ReIReSearch_logo.png" style="width:400px;margin:0px"></a>

                <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="navbarBasicExample">
                <span aria-hidden="true"></span>
                <span aria-hidden="true"></span>
                <span aria-hidden="true"></span>
                </a>
            </div>

            <div id="navbarBasicExample" class="navbar-menu">
                <div class="navbar-end">
                    <a href="{{ url('/') }}" class="navbar-item monda">Home</a>
                    <a href="{{ url('http://www.reires.eu/') }}" target="_blank" class="navbar-item monda">ReIReS</a>
                    <a href="{{ route('help') }}" class="navbar-item monda">Help</a>
                    <a href="{{ route('about') }}" class="navbar-item monda">About</a>
                    <!-- <a href="{{ route('feedback') }}">Feedback</a> -->
                    @auth
                    <a href="{{ route('profile.edit') }}" class="navbar-item monda">{{ __('Profile') }} : {{ Auth::user()->name }}</a>
                    <a href="{{ route('logout') }}" onclick="event.preventDefault();document.getElementById('logout-form').submit();" class="navbar-item monda">{{ __('Logout') }}&nbsp;<i class="fa fa-sign-out"></i></a>
                    <form id="logout-form" action="{{ route('logout') }}" method="POST" style="display: none;">
                        @csrf
                    </form>

                    @else
                        @if (Route::has('register'))
                            <a href="{{ route('register') }}" class="navbar-item monda">Register</a>
                        @endif
                        <a href="{{ route('login') }}" class="navbar-item monda">Login&nbsp;<i class="fa fa-sign-in"></i></a>
                    @endauth
                </div>
            </div>
            </nav>
        </div>
        <div class="">
            @yield('content')
        </div>
        <div class="box" style="margin-top:30px; font-size:14px; padding-bottom:10px; margin-bottom:25px">
            <div class="columns">
                <div class="column is-2">
                    Platform by<br><a href="http://www.libis.be" target="_blank"><img src="/img/libis.png" valign="center" style="height:41px;margin-bottom:10px"></a>
                </div>
                <div class="column is-4">
                    In collaboration with<br><a href="http://www.brepols.net/Pages/Home.aspx" target="_blank"><img src="/img/Brepols_logo.png" valign="center" style="height:41px;margin-bottom:10px"></a>
                </div>
                <div class="column is-6">
                    <a href="https://ec.europa.eu/programmes/horizon2020/en" target="_blank"><img src="/img/EU_emblem.png" style="height:68px;vertical-align:top;margin-right:8px"></a>
                    <p style="display:inline-block;font-family:Monda;font-weight:normal;font-size:15px;line-height:110%">
                    This project has received funding<br>
                    from the European Union's Horizon 2020<br>
                    research and innovation programme<br>
                    under grant agreement No 730895
                    </p>
                </div>
            </div>            
            <div class="content has-text-right">
                <a href="{{ route('privacy') }}">Privacy Policy</a> - <a href="{{ route('privacy') }}#cookies">Cookie Policy</a> - <a href="{{ route('tos') }}">Terms of Service</a>
            </div>
            
        </div>    
    </div>

</body>
</html>
