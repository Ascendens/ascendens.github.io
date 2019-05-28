<!DOCTYPE html>
<html lang="ru">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
        <title>@yield('page_title', $page->siteTitle)</title>
        <meta name="description" content="@yield('page_description', $page->siteDescription)">
        <meta name="author" content="Андрей Котельник">
        <meta name="viewport" content="width=device-width">
        <meta name="google-site-verification" content="srcHAgeuk6CVcbIN_EgR07rRYW1oG420EIbLWAB73P4" />
        @if($page->headers) @foreach($page->headers as $header) {!! $header !!} @endforeach @endif
        <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=PT+Serif:400,400italic,700%7CPT+Sans:400">
        <link rel="stylesheet" href="{{ mix('css/main.css', 'assets/build') }}">
        <!-- Icons -->
        <link rel="apple-touch-icon" sizes="144x144" href="/assets/images/apple-touch-icon-precomposed.png">
        <link rel="shortcut icon" href="/assets/images/favicon.ico">
    </head>

    <body>
        @include('_partials/sidebar')

        <div class="wrap">
            <div class="masthead">
                <header class="container">
                    <h3 class="masthead-title">
                        <a href="/" title="Home">{{ $page->siteTitle }}</a>
                        <small>{{ $page->siteDescription }}</small>
                    </h3>
                </header>
            </div>

            <main class="container content">@yield('body')</main>
        </div>
        <label for="sidebar-checkbox" class="sidebar-toggle"></label>
        @if($page->enableGoogleAnalytics)
            <script>
            (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
                (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
                m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
            })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');
            if (window.location.host.indexOf('local') === -1) {
                ga('create', 'UA-18144383-3', 'auto');
                ga('send', 'pageview');
            }
            </script>
        @endif
        @yield('bottom_js')
    </body>
</html>
