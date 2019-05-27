<?php

date_default_timezone_set('Europe/Kiev');

return [
    'production' => false,
    'baseUrl' => '',

    'siteTitle' => env('SITE_TITLE'),
    'siteDescription' => env('SITE_DESCRIPTION'),

    'excerpt' => function ($page) {
        return explode('<!--more-->', $page->getContent())[0];
    },

    'text' => function ($page) {
        /** @var object $page */
        if (false === strpos($page->getContent(), '<!--more-->')) {
            return $page->getContent();
        }

        return explode('<!--more-->', $page->getContent())[1];
    },

    'ru_date' => function($page, $format) {
        $monthMap = [
            'from' => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
            'to' => ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'],
        ];

        return str_replace($monthMap['from'], $monthMap['to'], date($format, $page->date));
    },

    'collections' => [
        'posts' => [
            'path' => '{permalink}',
            'sort' => '-date',
        ],
    ],
];
