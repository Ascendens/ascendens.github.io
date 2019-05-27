---
extends: _layouts.post
permalink: virtual-fields-in-datatables.html
title: Виртуальные поля в DataTables
description: Создание виртуальных, или содержащих комбинацию данных из других, полей в DataTables
date: 1496948280
---

Приходилось сталкиваться с [DataTables](https://datatables.net)? Однажды это случится. А еще, однажды вам понадобится
вывести поле, с данными, которых нет.

<!--more-->

Данные, которых нет... Тесты, которых нет... Ладно, не будем о грустном.

Предположим, у нас есть список имен и фамилий некоторых подозрительных личностей. Нам нужна таблица, в которой будут 
следующие колонки:

1. Имя.
2. Фамилия.
3. Имя + Фамилия (те самые загадочные данные).

Давайте начнем с малого и сделаем таблицу c идентификатором `names`, содержащую только имя и фамилию:

```javascript
// Прекрасно! Ничего лишнего!
$('#names').DataTable({
  data: [
      {firstName: 'John', lastName: 'Doe'},
      {firstName: 'Jane', lastName: 'Doe'}
    ],
    columns: [
      {title: "First name", data: "firstName"},
      {title: "Second name", data: "lastName"}
    ]
});
```

Появляется мысль, что этого достаточно, но руководство упорствует - они хотят колонку, где указано полное имя. Думая
разное про себя, идем читать документацию библиотеки и находим опцию
[columns.render](https://datatables.net/reference/option/columns.render).

Много хорошего и разного поволяет делать она. Дабы не усложнять, зададим значение по умолчанию `_`:

```javascript
columns: [
  {title: "First name", data: "firstName"},
  {title: "Second name", data: "lastName"},
  {
    title: "Full name",
    data: null,
    render: {
        _: function (rowData) {
        return rowData.firstName + ' ' + rowData.lastName;
      }
    }
  }
]
```

Вот и сбылась мечта - создано полноценное виртуальное поле!

> <del>Лицензия от</del> С полным рабочим примером можно ознакомиться прямо [здесь](https://jsfiddle.net/7dbj6vju/7/).
