---
extends: _layouts.post
permalink: repairing-of-the-loot-appraiser.html
title: Как я Loot Appraiser 1.9.3 чинил
description: Оказывается, в аддоне Loot Appraiser 1.9.3 имеются, как минимум, две ошибки и я расскажу, как их исправить. 
date: 1559161105
---

В недоумении, что это за Loot Appraiser? Не <del>мышонок</del> библиотека, не famework, а аддон к World of Warcraft. И в
этом материале я буду рассказывать, как фиксил два интересных бага в нем.

<!--more-->

[Loot Appraiser](https://wow.curseforge.com/projects/lootappraiser) &mdash; это аддон, который позволяет учитывать доход
от [фарма](https://ru.wikipedia.org/wiki/%D0%A4%D0%B0%D1%80%D0%BC%D0%B5%D1%80_(MMORPG)). Штука, несомненно, хорошая и
полезная, но с двумя неприятными недочетами (как минимум, в версии 1.9.3), которые не позволяют разгуляться на полную.

<h2 id="fast-fix">Fast fix</h2>

Для тех, кто по ссылке под роликом [Полный мониторинг фарма. Исправления и настройка Loot Appraiser](https://youtu.be/fptQnrpQvtA)
и не сильно горит желанием разбираться в истоках описанных там проблем:

1. Откройте папку c файлами World of Warcraft.
2. Перейдите в `_retail_\Interface\AddOns\LootAppraiser`.
3. Замените файл <span class="important">LootAppraiser.lua</span> на [этот](/assets/files/repairing-of-the-loot-appraiser/LootAppraiser.lua).
4. Перейдите в `_retail_\Interface\AddOns\LootAppraiser\Core`.
5. Замените файл <span class="important">Util.lua</span> на [этот](/assets/files/repairing-of-the-loot-appraiser/Util.lua).
6. Запустите игру, или сделайте `/restart`, если она уже запущена.

Более любознательных приглашаю к дальнейшему чтению!

## Баг №1. Неправильный парсинг полученного золота

При фарме попадаются как предметы, так и золото. Каждый аспект учитывается отдельно. Количество золота аддон получает из
сообщений чата &mdash; они конвертируются в число функцией `Util.StringToMoney` из файла _Core\Util.lua_:

```
-- parse currency text from loot window and covert the result to copper
-- e.g. 2 silve, 2 copper -> 202 copper
function Util.StringToMoney(lootedCurrencyAsText)
    local digits = {}
    local digitsCounter = 0;
    lootedCurrencyAsText:gsub("%d+",
        function(i)
            table.insert(digits, i)
            digitsCounter = digitsCounter + 1
        end
    )
    local copper = 0
    if digitsCounter == 3 then
        -- gold + silber + copper
        copper = (digits[1]*10000)+(digits[2]*100)+(digits[3])
    elseif digitsCounter == 2 then
        -- silber + copper
        copper = (digits[1]*100)+(digits[2])
    else
        -- copper
        copper = digits[1]
    end

    return copper
end
```

Как видно, строка преобразуется в таблицу чисел &mdash; по 1 столбцу для каждого порядка &mdash; через регулярное
выражение `%d+`. По задумке авторов, строка вида `2 silve, 2 copper` станет таблицей `1 1`, а после, числом 202. Но для
русской локализации, сообщение имеет следующий вид:

```
 Ваша добыча: 2 |4серебряная:серебряные:серебряных;, 2 |4медная монета:медные монеты:медных монет;.
```

Не вникал, как это разбирает клиент WoW, но вышеприведенная функция выберет все цифры, что даст таблицу `2 4 2 4`, а
после, так как столбцов аж 4, применит последнее условие и получится число 2. Для того, чтобы разбор велся верно,
подкорректировать ругулярку:
```
-- Выбираем только последовательности цифр, после которых есть один пробел
lootedCurrencyAsText:gsub("%d+%s", -- Строка 86
```

Теперь, сообщение будет преобразовано в `2 4`, применится второе условие, а на выходе будет `2 * 100 + 2 = 202`.

## Баг №2. Неверные данные о цене от TSM, если предмет еще не в кэше

Еще один must have аддон &mdash; Trade Skill Master. Он добавляется множество нужного функционала, но в нашем случае
интересны источники цен. Loot Appraiser использует API от Trade Skill Master, чтобы оценить потенциальную стоимость
предмета. Беда лишь в том, что для впервые встреченных вещей, TSM возвращает 0, а потом таки достает реальную стоимость
в фоне и далее будет возвращать искомые данные в полном объеме.

Здесь пришлось пошаманить немного больше. Есть в файле _LootAppraiser.lua_ фукнция `private.HandleItemLooted`, которая
вызывается каждый раз, когда предмет попадает в сумку. В ней в, строке 513, вычисляется конечная стоимость набора:

```
local itemValue = singleItemValue * quantity
```

Я решил делать рекурсивный вызов `private.HandleItemLooted` каждые 300 мс до 5 раз, в надежде, что за это время TSM
обновит данные и вернет правильную стоимость. Спойлеры, обычно правильная цена возвращается в ответ на уже второй
запрос.

```
-- resolve price timer - это линия 512
if 0 == singleItemValue then -- Если цена таки не определилась
    if not ticker then -- И тикер не обьявлен
        LA.Debug.Log("Single item value of "  .. tostring(itemID) .. ": " .. tostring(itemLink) .. " was not resolved. Trying to repeat")
        -- Стартуем тикер со всеми нужными параметрами
        ticker = C_Timer.NewTicker(0.3, private.resolvePriceTimerClosure, 5)
        ticker.params = { itemLink = itemLink, itemID = itemID, quantity = quantity, source = source, priceSource = priceSource }
    end
    -- Если тикер не отменен и количество оставшихся итераций больше 1, то прерываем выполнение
    if ticker and not ticker._cancelled and ticker._remainingIterations > 1 then
        LA.Debug.Log("Tiker has been started. Going to next iteration for "  .. tostring(itemID) .. ": " .. tostring(itemLink))

        return
    end
    -- Сюда мы попадем, если прошло 5 итераций, но цена так и  не была определена
    LA.Debug.Log("Price of "  .. tostring(itemID) .. ": " .. tostring(itemLink) .. " was not resolved. Timer aborted")
end
```

Сама функция `private.resolvePriceTimerClosure` может быть помещена в конец файла:

```
-- retry to fetch item price
function private.resolvePriceTimerClosure(ticker)
	local params = ticker.params
	local tsmPrice = LA.TSM.GetItemValue(params.itemID, params.priceSource) or 0 -- Пытаемся получить цену
    -- Если получили
	if tsmPrice > 0 then
		LA.Debug.Log("Price of "  .. tostring(params.itemID) .. ": " .. tostring(params.itemLink) .. " has been resolved: " .. tostring(tsmPrice))
		ticker:Cancel() -- Отменяем тикер, что позволит добавить вещь в список и правильно сложить его цену
	else
		LA.Debug.Log("Timer for "  .. tostring(params.itemID) .. ": " .. tostring(params.itemLink) .. " will be runned " .. tostring(ticker._remainingIterations) .. " more times")
	end
	-- Делаем вызов private.HandleItemLooted
	private.HandleItemLooted(params.itemLink, params.itemID, params.quantity, params.source, ticker)
end
```

Внимательный читатель заметит, что сигнатура фукнции `private.HandleItemLooted` не содержит последнего аргумента
`ticker` и будет прав. Нужно обновить сигнатуру в строке 441 на:

```
function private.HandleItemLooted(itemLink, itemID, quantity, source, ticker)
```

Теперь все должно работать. Не закэшированные вещи будут добавлены в список позже на 300 миллисекунд, зато с правильной
ценой.

## Бонус. Как увидеть debug log в игре?

Если есть желание поработать с кодом самостоятельно, подскажу, как включить отображение логов, отправленных через
`LA.Debug.Log`. Необходимо создать окно чата с именем **LADebug**. Это все.