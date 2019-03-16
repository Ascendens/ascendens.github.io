let mix = require('laravel-mix');
let build = require('./tasks/build.js');

mix.disableSuccessNotifications();
mix.setPublicPath('source/assets/build');
mix.webpackConfig({
    plugins: [
        build.jigsaw,
        build.browserSync(),
        build.watch(['source/**/*.md', 'source/**/*.php', 'source/**/*.css', '!source/**/_tmp/*']),
    ]
});

mix
    // .js('source/_assets/js/main.js', 'js')
    .styles(
        [
            'source/_assets/css/poole.css',
            'source/_assets/css/lanyon.css',
            'source/_assets/css/stynax.css',
            'source/_assets/css/style.css'
        ],
        'source/assets/build/css/main.css'
    )
    .options({
        processCssUrls: false,
    })
    .version();
