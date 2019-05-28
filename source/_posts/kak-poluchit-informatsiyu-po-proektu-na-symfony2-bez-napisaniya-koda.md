---
extends: _layouts.post
permalink: kak-poluchit-informatsiyu-po-proektu-na-symfony2-bez-napisaniya-koda.html
title: "Symfony2: как получить информацию по проекту без написания кода"
description: Получение информации о платформе и библиотеках PHP через Composer
date: 1398701060
---

Иногда бывает нужно узнать информацию по установленным модулям PHP или же используемым bundle'ам, а писать
дополнительный код, вроде файла с [phpinfo](https://php.net/manual/ru/function.phpinfo.php) или лезть в конфигурацию
composer'а так лень. Выход есть!

<!--more-->

<h2 id="">Информация о платформе<a href="#" class="anchor">#</a></h2>

```bash
php composer.phar show --platform
```

После ввода такой команды, вы&nbsp;получите информацию по всем установленным в системе надстройкам PHP. Выглядит вывод
приблизительно вот так:

![Информация об PHP окружении](/assets/images/kak-poluchit-informatsiyu-po-proektu-na-symfony2-bez-napisaniya-koda/1.jpg)

<h2 id="-2">Информация о установленных библиотеках<a href="#-2" class="anchor">#</a></h2>

```bash
php composer.phar show --installed
```

С помощью этой команды вы можете получить информацию об всех установленных библиотеках. Выглядит результат
очень похоже:

![Информация о установленных библиотеках](/assets/images/kak-poluchit-informatsiyu-po-proektu-na-symfony2-bez-napisaniya-koda/2.jpg)

А если хочется почитать почти то же, но на английском, то ссылку на оригинал можно найти
[здесь](https://twitter.com/Ascendens_Dark/status/453856889043181568).