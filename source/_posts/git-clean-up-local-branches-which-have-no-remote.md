---
extends: _layouts.post
permalink: git-clean-up-local-branches-which-have-no-remote.html
title: Git. Удаляем все локальные ветки, отслеживающие удаленные с сервера
description: Как одной командой удалить локальные ветки, отслеживающие удаленные на сервере
date: 1500495080
---

В своей работе я использую [Git flow](https://danielkummer.github.io/git-flow-cheatsheet/). Все бы хорошо, но после
деплоя обнаруживается, что на локальной машине осталось множество веток, которые слиты в рабочую ветку и удалены на
сервере. Хочу представить вариант уборки такого бардака.

<!--more-->

В Git есть ветки локальные, ветки на сервере и локальные копии веток на сервере, на которые
[ориентируются](https://stackoverflow.com/questions/4693588/git-what-is-a-tracking-branch) локальные. Если ввести
команду [git branch -a](https://git-scm.com/docs/git-branch), то список последних будет находиться в самом конце. В
Git 2.7.4 названия начинаются на **remotes/**, например, **remotes/origin/master**.

```bash
user@system:~/Project$ git branch
* develop
  master
  feature/one
  feature/two
  remotes/origin/HEAD -&gt; origin/master
  remotes/origin/develop
  remotes/origin/master
  remotes/origin/feature/one
```

Теперь посмотрим связь локальных веток с удаленными (локальные в начале, а отслеживаемые в квадратных скобках)

```bash
user@system:~/Project$ git branch -vv
* develop      0fffd86 [origin/develop] Commit message
  master       f72fd61 [origin/master] Another commit message
  feature/one  506f204 [origin/feature/one] One description
  feature/two  a3c5e7d Very local branch
```

Есть в Git такая штука [git remote prune](https://git-scm.com/docs/git-remote). Она позволяет очистить локальные копии
удаленных веток, которых на сервере уже нет. При этом, *совсем* локальные ветки никак не затрагиваются. Удалим с сервера
ветку **feature/one** и посмотрим связь снова.

```bash
user@system:~/Project$ git push origin --delete feature/one
user@system:~/Project$ git remote prune origin
user@system:~/Project$ git branch -vv
* develop      0fffd86 [origin/develop] Commit message
  master       f72fd61 [origin/master] Another commit message
  feature/one  506f204 [origin/feature/one: пропал] One description
  feature/two  a3c5e7d Very local branch
```

Ветка **feature/one** все еще отслеживает **origin/feature/one**, но последней нет ни на сервере, ни в списке
**remotes/**, о чем говорит нам слово "пропал". Найти все пропавшие ветки и вывести их список через пробел можно,
например, вот так:

```bash
git branch -vv | awk '/\[(.+):\sпропал\]/ {print $1}' | paste -d ' ' -s
```

Ещё немного, ещё чуть-чуть, как поется в известной песне. Вспоминаем как удалять локальные ветки и получаем решение:

```bash
git remote prune origin && git branch -d $(git branch -vv | awk '/\[(.+):\sпропал\]/ {print $1}' | paste -d ' ' -s)
```

> Точно актуально для  Git 2.7.4 c русской локализацией. И не говорите, что я не предупреждал.
