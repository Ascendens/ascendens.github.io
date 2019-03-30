<?php

return [
    'production' => false,
    'baseUrl' => '',

    'siteTitle' => env('SITE_TITLE'),
    'siteDescription' => env('SITE_DESCRIPTION'),

    'excerpt' => function ($page) {
        return explode('<!--more-->', $page->getContent())[0];
    },
    'text' => function ($page) {
        if (false === strpos($page->getContent(), '<!--more-->')) {
            return $page->getContent();
        }

        return explode('<!--more-->', $page->getContent())[1];
    },

    'collections' => [
        'posts' => [
            'path' => '{permalink}',
        ],
    ],
];
