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

        <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/highlight.min.js"></script>
        <script>hljs.initHighlightingOnLoad();</script>
    </body>
</html>
