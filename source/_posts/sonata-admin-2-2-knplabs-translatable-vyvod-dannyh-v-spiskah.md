---
extends: _layouts.post
permalink: sonata-admin-2-2-knplabs-translatable-vyvod-dannyh-v-spiskah.html
title: Sonata Admin 2.2 + KnpLabs Translatable. Вывод данных в списках
description: Вывод локализированных через KnpLabs Translatable данных в списках Sonata Admin 2.2
date: 1408377209
---

Впервые попытавшись работать в Sonata Admin с сущностями, переводы которых обеспечивал KnpLabs Translatable, я наткнулся
на неприятный момент — нет очевидного варианта выводить данные нужной локали в списках. О своем решении этого вопроса
я бы хотел сегодня рассказать.

<!--more-->

Sonata Admin достаточно мощный инструмент и обладает таким замечательным функционалом, как автоматическое определение
типа данных в поле, а также вывод данных связанных сущностей. Но, в случае с KnpLabs Translatable, мощности 
оказалось недостаточно и пришлось придумывать свое решение. Как только я не пытался получить информацию из переводов.

```php
protected function configureListFields(ListMapper $listMapper)
{
  $listMapper
    ->add('title')
    ->add('translations.title')
    ->add('translations.ru.title')
  ;
}
```

Но ничего не помогало — колонка таблицы была просто пуста. Не помогло и добавление метода _call в сущность, о котором
можно [почитать в официальной документации](https://github.com/KnpLabs/DoctrineBehaviors#proxy-translations).

На выручку пришла возможность создавать свои шаблоны для полей списка в Sonata Admin, а также небольшая модификация того
самого "волшебного" механизма проксирования. Получилось вот так:

```php
class Entity 
{
  public function __call($method, $arguments)
  {
    if( !empty($arguments[0]) && is_array($arguments[0]) 
        && array_key_exists('locale', $arguments[0]) 
    ) {
      $this->setCurrentLocale($arguments[0]['locale']);
    }

    return $this->proxyCurrentLocaleTranslation($method, $arguments);
  }
}
```

Вот такой шаблон:

```twig
{% set fieldName = 'get' ~ field_description.options.field %}
{% set value = attribute( object, fieldName, [{ 'locale': field_description.options.locale }] ) %}

{% if field_description.type == 'text' %}
    {% include 'SonataAdminBundle:CRUD:base_list_field.html.twig' with { 'value': value } %}
{% else %}
    {% include 'SonataAdminBundle:CRUD:list_' ~ field_description.type ~ '.html.twig' with { 'value': value } %}
{% endif %}
```

И такой код вызова шаблона в классе Admin:

```php
protected function configureListFields(ListMapper $listMapper)
{
  $listMapper
    ->add('title_ru', null, , array(
        'field' => 'title', //Имя поле, данные которого нужно вывести
        'label' => 'Заголовок (RU)',
        'template' => 'translatable.html.twig', //Имя шаблона, где находится код из блока повыше
        'locale' => 'ru'
      ))
  ;
}
```

Теперь данные отлично выводятся. Неудобство только в том, что если содержимое не является текстом, нужно конкретно
указать тип поля, чтобы на полную использовать оформление Sonata Admin, но, возможно, есть способ этот вопрос решить.
Если я найду панацею, то обязательно поделюсь ней с вами. Следите за обновлениями!
