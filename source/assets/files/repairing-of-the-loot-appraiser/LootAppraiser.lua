local LA = select(2, ...)

local LibStub = LibStub
local AceGUI = LibStub("AceGUI-3.0")
local LibToast = LibStub("LibToast-1.0")
local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")
local LibParse = LibStub:GetLibrary("LibParse")

local TUJMarketInfo = TUJMarketInfo
local LootAppraiser_GroupLoot = LootAppraiser_GroupLoot


-- Lua APIs
local select, tostring, time, unpack, tonumber, floor, pairs, tinsert, smatch, math, gsub = 
select, tostring, time, unpack, tonumber, floor, pairs, table.insert, string.match, math, gsub

-- wow APIs
local GetContainerItemID, GetContainerItemInfo, GetUnitName, GetItemInfo, IsShiftKeyDown, InterfaceOptionsFrame_OpenToCategory, GetBestMapForUnit, PlaySoundFile, GameFontNormal, RegisterAddonMessagePrefix, IsInGroup, UnitGUID, SecondsToTime, StaticPopupDialogs, StaticPopup_Show, SendAddonMessage =
GetContainerItemID, GetContainerItemInfo, GetUnitName, GetItemInfo, IsShiftKeyDown, InterfaceOptionsFrame_OpenToCategory, C_Map.GetBestMapForUnit, PlaySoundFile, GameFontNormal, C_ChatInfo.RegisterAddonMessagePrefix, IsInGroup, UnitGUID, SecondsToTime, StaticPopupDialogs, StaticPopup_Show, C_ChatInfo.SendAddonMessage
local INSTANCE_RESET_SUCCESS, OKAY, LOOT_ITEM_SELF, LOOT_ITEM_SELF_MULTIPLE = INSTANCE_RESET_SUCCESS, OKAY, LOOT_ITEM_SELF, LOOT_ITEM_SELF_MULTIPLE


local private = {
    modules = {}
}


-- global api object
LA_API = {}
LA.LA_API = LA_API

function LA_API.RegisterModule(theModule)
    LA.Debug.Log("RegisterModule")
	LA.Debug.TableToString(theModule)

    if not private.modules then
        private.modules = {}
    end

    private.modules[theModule.name] = theModule
end

function LA_API.GetVersion()
    return LA.CONST.METADATA.VERSION
end

function LA_API.StartSession(qualityFilter, priceSource, ...)
	if not qualityFilter or not priceSource then
		return
	end

	local startPaused
	for i = 1, select('#', ...) do
		local opt = select(i, ...)
		if opt == nil then
			-- do nothing
		elseif opt == "START_PAUSED" then
			startPaused = true
		end
	end

	LA.db.profile.general.qualityFilter = qualityFilter
	LA.db.profile.pricesource.source = priceSource

	LA.Session.Start(true)	-- start session
	LA.Session.New()		-- force new session in case a session is already running
	if startPaused then
		LA.Session.Pause()	-- and pause session
	end
end

function LA_API.GetCurrentSession()
	return LA.Session.GetCurrentSession()
end

function LA_API.PauseSession()
	LA.Session.Pause()
end


-- AceAddon-3.0 standard methods
function LA:OnInitialize()
    private.InitDB()

	LA.Debug.Log("LA:OnInitialize()")

	LA:SetSinkStorage(LA.db.profile.notification.sink)

	-- prepare minimap icon --
	LA.icon = LibStub("LibDBIcon-1.0")
	LA.LibDataBroker = LibStub("LibDataBroker-1.1"):NewDataObject(LA.CONST.METADATA.NAME, {
		type = "launcher",
		text = "Loot Appraiser sadasd", -- for what?
		icon = "Interface\\Icons\\Ability_Racial_PackHobgoblin",

		OnClick = function(self, button, down)
			if button == "LeftButton" then
				local isShiftKeyDown = IsShiftKeyDown()
				if isShiftKeyDown then
					local callback = private.GetMinimapIconModulCallback("LeftButton", "Shift")
					if callback then
						callback()
					end
				else
					if not LA.Session.IsRunning() then
				        LA.Session.Start(true)
				    end

				    LA.UI.ShowMainWindow(true)
				end
			elseif button == "RightButton" then
				local isShiftKeyDown = IsShiftKeyDown()
				if isShiftKeyDown then
					local callback = private.GetMinimapIconModulCallback("RightButton", "Shift")
					if callback then
						callback()
					end
				else
					InterfaceOptionsFrame_OpenToCategory(LA.CONST.METADATA.NAME)
					InterfaceOptionsFrame_OpenToCategory(LA.CONST.METADATA.NAME)
				end
			end
		end,

		OnTooltipShow = function (tooltip)
			tooltip:AddLine(LA.CONST.METADATA.NAME .. " " .. LA.CONST.METADATA.VERSION, 1 , 1, 1)
			tooltip:AddLine("|cFFFFFFCCLeft-Click|r to open the main window")
			tooltip:AddLine("|cFFFFFFCCRight-Click|r to open options window")
			tooltip:AddLine("|cFFFFFFCCDrag|r to move this button")
			tooltip:AddLine(" ") -- spacer

			if LA.Session.IsRunning() then
				local offset = LA.Session.GetPauseStart() or time()
				local delta = offset - LA.Session.GetCurrentSession("start") - LA.Session.GetSessionPause()

				-- don't show seconds
				local noSeconds = false
				if delta > 3600 then
					noSeconds = true
				end

				local text = "Session is "
				if LA.Session.IsPaused() then
					text = text .. "paused: "
				else
					text = text .. "running: "
				end

				tooltip:AddDoubleLine(text, SecondsToTime(delta, noSeconds, false))
			else
				tooltip:AddLine("Session is not running")
			end

			-- if module present we add the additional modul informations
			if private.modules then
				for name, module in pairs(private.modules) do
					if module.icon and module.icon.tooltip then
						-- add lines
						tooltip:AddLine(" ") -- spacer

						for _, line in pairs(module.icon.tooltip) do
							tooltip:AddLine(line)
						end
					end
				end
			end
		end
	})
	LA.icon:Register(LA.CONST.METADATA.NAME, LA.LibDataBroker, LA.db.profile.minimapIcon)
	if LA.db.profile.minimapIcon.hide == true then
		LA.icon:Show(LA.CONST.METADATA.NAME)
	else
		LA.icon:Hide(LA.CONST.METADATA.NAME)
	end
end

function LA:OnEnable()
    LA:Print("ENABLED.")

    private.PreparePricesources()

    -- register chat commands
    LA:RegisterChatCommand("la", private.chatCmdLootAppraiser)
    LA:RegisterChatCommand("lal", private.chatCmdLootAppraiserLite)
    LA:RegisterChatCommand("laa", private.chatCmdGoldAlertTresholdMonitor)
    LA:RegisterChatCommand("lade", private.chatCmdUseDisenchantValueStatus)

	-- register event for reset instance
	LA:RegisterEvent("CHAT_MSG_SYSTEM", private.OnResetInfoEvent)
	LA:RegisterEvent("CHAT_MSG_ADDON", private.OnChatMsgAddon)

    -- register event for...
    -- ...looting items (new loot tracking logic)
    LA:RegisterEvent("CHAT_MSG_LOOT", private.OnChatMsgEvents)
	-- ...looting currency
	LA:RegisterEvent("CHAT_MSG_MONEY", private.OnChatMsgMoney)

	-- register addon message prefix for LootAppraiser_GroupLoot
    RegisterAddonMessagePrefix(LA.CONST.PARTYLOOT_MSGPREFIX)
end

-- self loot
-- ...single item - "You receive loot: %s." -> item
local PATTERN_LOOT_ITEM_SELF = LOOT_ITEM_SELF:gsub("%%s", "(.+)")
-- ...multiple item - "You receive loot: %sx%d." -> item + quantity
local PATTERN_LOOT_ITEM_SELF_MULTIPLE = LOOT_ITEM_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")


function private.OnChatMsgEvents(event, msg)

    -- is a loot appraiser session running?
    if not LA.Session.IsRunning() then return end

	-- pause? restart session
	if LA.Session.IsPaused() then
		LA.Session.Restart()
	end

	-- loot
	if event == "CHAT_MSG_LOOT" then
		-- self
		local loottype, itemLink, quantity, source
		if msg:match(PATTERN_LOOT_ITEM_SELF_MULTIPLE) then
			loottype = "## self (multi) ##"
			itemLink, quantity = smatch(msg, PATTERN_LOOT_ITEM_SELF_MULTIPLE)

		elseif msg:match(PATTERN_LOOT_ITEM_SELF) then
			loottype = "## self (single) ##"
			itemLink = smatch(msg, PATTERN_LOOT_ITEM_SELF)
			quantity = 1
		end

		if loottype then
			LA.Debug.Log("#### type=%s; itemLink=%s; quantity=%s", loottype, tostring(itemLink), tostring(quantity))
			if not itemLink or not quantity then
				LA.Print("#### ignore event! msg: " .. msg .. ", type=" .. tostring(loottype))
				LA.Print("   itemLink=" .. tostring(itemLink) .."; quantity=" .. tostring(quantity) .. "; source=" .. tostring(source) .. ")")
				return
			end

			local itemID = LA.Util.ToItemID(itemLink)

			private.HandleItemLooted(itemLink, itemID, quantity, source)
		end
	end
end


function private.GetMinimapIconModulCallback(button, modifier)
	-- if modules present we add the additional callbacks
	if not private.modules then return end

	for name, module in pairs(private.modules) do
		if module.icon and module.icon.action then
			for _, action in pairs(module.icon.action) do
				if action.button == button then
					if action.modifier == modifier then
						return action.callback
					end
				end
			end
		end
	end
end


function private.PreparePricesources()
	LA.Debug.Log("PreparePricesources()")

	-- price source check --
	local priceSources = private.GetAvailablePriceSources() or {}

	-- only 2 or less price sources -> chat msg: missing modules
	if LA.Util.tablelength(priceSources) <= 2 then
		StaticPopupDialogs["LA_NO_PRICESOURCES"] = {
			text = "|cffff0000Attention!|r Missing additional addons for price sources (e.g. like TradeSkillMaster or The Undermine Journal).\n\n|cffff0000LootAppraiser disabled.|r",
			button1 = OKAY,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true
		}
		StaticPopup_Show("LA_NO_PRICESOURCES")

		LA:Print("|cffff0000LootAppraiser disabled.|r (see popup window for further details)")
		LA:Disable()
		return
	else
		-- current preselected price source
		local priceSource = LA.GetFromDb("pricesource", "source") -- die voreingestellte Preisquelle von LA

		-- price source 'custom'
		if priceSource == "Custom" then
			-- validate 'custom' price source
			local isValidCustomPriceSource = LA.TSM.ParseCustomPrice(LA.GetFromDb("pricesource", "customPriceSource"))
			if not isValidCustomPriceSource then
				StaticPopupDialogs["LA_INVALID_CUSTOM_PRICESOURCE"] = {
					text = "|cffff0000Attention!|r You have selected 'Custom' as price source but your formular is invalid (see TSM documentation for detailed custom price source informations).\n\n" .. (LA.GetFromDb("pricesource", "customPriceSource") or "-empty-"),
					button1 = OKAY,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true
				}
				StaticPopup_Show("LA_INVALID_CUSTOM_PRICESOURCE")
			end
		else
			-- normal price source check against prepared list
			if not priceSources[priceSource] then
				StaticPopupDialogs["LA_INVALID_CUSTOM_PRICESOURCE"] = {
					text = "|cffff0000Attention!|r Your selected price source in Loot Appraiser is not or no longer valid (maybe due to a missing module/addon). Please select another price source in the Loot Appraiser settings or install the needed module/addon for the selected price source.",
					button1 = OKAY,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true
				}
				StaticPopup_Show("LA_INVALID_CUSTOM_PRICESOURCE")
			end
		end
	end

	LA.availablePriceSources = priceSources

	--if TUJTooltip then
		--TUJTooltip(LA.db.profile.display.enableTUJTooltip)
	--end
end


-- propagate group loot
function private.SendAddonMsg(...)
	if LootAppraiser_GroupLoot then
		return
	end

	local json = ""
	for n=1, select('#', ...) do
		if json ~= "" then
			json = json .. "\001"
		end
		json = json .. LibParse:JSONEncode(select(n,...))
	end

	-- add UnitGUID
	if json ~= "" then
		json = json .. "\001"
	end
	json = json .. LibParse:JSONEncode(UnitGUID("player"))

	SendAddonMessage(LA.CONST.PARTYLOOT_MSGPREFIX, json, "RAID") -- RAID, with fallback to PARTY if not in a raid
end


function private.OnChatMsgAddon(event, prefix, msg, type, sender)

	-- is a loot appraiser session running?
	if not LA.Session.IsRunning() then return end

    --LA.Debug.Log("#### OnChatMsgAddon: prefix: %s; msg: %s", tostring(prefix), tostring(msg))

	-- is message for loot appraiser?
	if prefix ~= LA.CONST.PARTYLOOT_MSGPREFIX then
        --LA.Debug.Log("#### OnChatMsgAddon: wrong prefix: %s", tostring(prefix))
		return
    end

	LA.Debug.Log("sender vs. player: %s vs. %s", sender, GetUnitName("player", true))
	if sender == GetUnitName("player", true) then
		LA.Debug.Log("#### OnChatMsgAddon: ignore message")
		return
	end

	local tokens = LA.Util.split(msg, "\001")
	local v = {}
	for i=1, #tokens do
		local temp = LibParse:JSONDecode(tokens[i])
		tinsert(v, temp)
	end

	local success, itemLink, itemID, quantity, senderUnitGUID = true, unpack(v)

	LA.Debug.Log("senderGUID vs. playerGUID: %s vs. %s", senderUnitGUID, UnitGUID("player"))
	if senderUnitGUID == UnitGUID("player") then
		LA.Debug.Log("OnChatMsgAddon: ignore message")
		return
	end

	LA.Debug.Log("OnChatMsgAddon: prefix=%s, msg=%s, type=%s, sender=%s", prefix, msg, type, senderUnitGUID)
	private.HandleItemLooted(itemLink, itemID, quantity, sender)
end


function private.OnChatMsgMoney(event, msg)
	if not LA.Session.IsRunning() then return end

	LA.Debug.Log("  OnChatMsgMoney: msg=%s", tostring(msg))

	local lootedCopper = LA.Util.StringToMoney(msg)

	LA.Debug.Log("    lootedCopper=%s", tostring(lootedCopper))
	private.HandleCurrencyLooted(lootedCopper)
end


-- open gold alert treshold monitor
function private.chatCmdGoldAlertTresholdMonitor()
    if not LA.Session.IsRunning() then
        LA.Session.Start(true)
    end

    LA.UI.ShowLastNoteworthyItemWindow()
end


-- Print the value of useDisenchantValue
function private.chatCmdUseDisenchantValueStatus()
	LA:Print(tostring(LA.GetFromDb("pricesource", "useDisenchantValue", "TSM_REQUIRED")))
end


-- open loot appraiser and start a new session
function private.chatCmdLootAppraiser(input)
	-- first: reset frames if requested
	if input == "freset" then LA.UI.ResetFrames() end

    if not LA.Session.IsRunning() then
		LA.Session.Start(true)
	end
    LA.UI.ShowMainWindow(true)
end


-- open loot appraiser lite and start a new session
function private.chatCmdLootAppraiserLite()
    if not LA.Session.IsRunning() then
        LA.Session.Start(false)
    end
    LA.UI.ShowLiteWindow()
end


-- the main logic for item processing
function private.HandleItemLooted(itemLink, itemID, quantity, source, ticker)
	LA.Debug.Log("handleItemLooted itemID=%s", itemID)
	LA.Debug.Log("  " .. tostring(itemID) .. ": " .. tostring(itemLink) .. " x" .. tostring(quantity)) --gsub(itemLink, "\124", "\124\124");
	LA.Debug.Log("  " .. tostring(itemID) .. ": " .. tostring(gsub(tostring(itemLink), "\124", "\124\124")))

    if not LA.Session.IsRunning() then return end

    -- settings we need
    local qualityFilter = tonumber(LA.GetFromDb("general", "qualityFilter"))
    local priceSource = LA.GetFromDb("pricesource", "source")
    local ignoreSoulboundItems = LA.GetFromDb("general", "ignoreSoulboundItems")

    local addItem2List = true -- normally we add the item to the list if we reach this part of the logic
    local disenchanted = false -- indicator for disenchat value

	local showLootedItemValueGroup = LA.GetFromDb("display", "showLootedItemValueGroup")
	local addGroupDropsToLootedItemList = LA.GetFromDb("display", "addGroupDropsToLootedItemList")

	local showGroupLoot = source and (showLootedItemValueGroup or addGroupDropsToLootedItemList)
	LA.Debug.Log("showGroupLoot = %s", tostring(showGroupLoot))

    -- always count the looted items
--    if quantity then
--        LA.Session.private.totalItemLootedCounter = LA.Session.private.totalItemLootedCounter + quantity
--    end

    -- check the item quality
    local quality = select(3, GetItemInfo(itemID)) or 0
    if quality < qualityFilter then
        LA.Debug.Log("  " .. tostring(itemID) .. ": item quality (" .. tostring(quality) .. ") < filter (" .. tostring(qualityFilter) .. ") -> ignore item")
        return
    end
    LA.Debug.Log("  " .. tostring(itemID) .. ": item quality (" .. tostring(quality) .. ") >= filter (" .. tostring(qualityFilter) .. ")")

    -- item blacklisted?
    if LA.IsItemBlacklisted(itemID) then
        LA.Debug.Log("  " .. tostring(itemID) .. ": blacklisted -> ignore")
        return
    end

    -- overwrite link if we only want base items
    if LA.GetFromDb("general", "ignoreRandomEnchants") then
        itemLink = select(2, GetItemInfo(itemID)) -- we use the link from GetItemInfo(...) because GetLootSlotLink(...) returns not the base item
    end

    -- special handling for poor quality and vendor filter items
    if quality == 0 then
        LA.Debug.Log("  " .. tostring(itemID) .. ": poor quality -> price source 'VendorSell'")
        priceSource = "VendorSell"
    elseif LA.CONST.ITEM_FILTER_VENDOR[tostring(itemID)] then
        LA.Debug.Log("  " .. tostring(itemID) .. ": item filtered by vendor list -> price source 'VendorSell'")
        priceSource = "VendorSell"
    end

    -- get single item value
    local singleItemValue = private.GetItemValue(itemID, priceSource) or 0
    LA.Debug.Log("  " .. tostring(itemID) .. ": single item value: " .. tostring(singleItemValue))

    -- special handling for soulbound items and activated disenchant value
    if singleItemValue == 0 and quality > 0 then
        if ignoreSoulboundItems then
            addItem2List = false
        end

        if LA.GetFromDb("pricesource", "useDisenchantValue", "TSM_REQUIRED") then
            singleItemValue = private.GetItemValue(itemID, "Destroy") or 0
            disenchanted = true
            LA.Debug.Log("  " .. tostring(itemID) .. ": single item value (de): " .. tostring(singleItemValue))
        end
    end

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

    -- calc the overall item value (get the quantity into the formular)
    local itemValue = singleItemValue * quantity

    private.IncLootedItemCounter(quantity, source)              -- increase looted item counter
    private.AddItemValue2LootedItemValue(itemValue, source)     -- add item value
    if addItem2List then
        LA.UI.AddItem2LootCollectedList(itemID, itemLink, quantity, itemValue, false, source, disenchanted)	-- add item
    end

    -- gold alert treshold
    local goldValue = floor(singleItemValue/10000)
    local gat = LA.GetFromDb("general", "goldAlertThreshold")
    if goldValue >= tonumber(gat) then
        LA.Debug.Log("  " .. tostring(itemID) .. ": gold value (" .. tostring(goldValue) .. ") >= gold alert threshold (" .. gat .. ")")

        -- prepare party loot suffix
        local partyLootSuffix = ""
        if source then
            partyLootSuffix = " (|cFF2DA6ED" .. source .. "|r)"
        end

        -- inc noteworthy items counter
        private.IncNoteworthyItemCounter(quantity, source)

        -- print to configured output 'channels'
		if not source or showGroupLoot then
			local formattedValue = LA.Util.MoneyToString(singleItemValue) or 0
			LA:Pour(itemLink .. " x" .. quantity .. ": " .. formattedValue .. partyLootSuffix)

			-- last noteworthy item ui
			LA.UI.UpdateLastNoteworthyItemUI(itemLink, quantity, formattedValue)

			-- toast
			if LA.GetFromDb("notification", "enableToasts") then
				local name, _, _, _, _, _, _, _, _, texturePath = GetItemInfo(itemID)
				LibToast:Spawn("LootAppraiser", name, texturePath, quality, quantity, formattedValue, source)
			end

			-- play sound (if enabled)
			if LA.GetFromDb("notification", "playSoundEnabled") then
				--PlaySound("AuctionWindowOpen", "master");
				local soundName = LA.db.profile.notification.soundName or "None"
				PlaySoundFile(LSM:Fetch("sound", soundName), "master")
			end
		end

        -- check current mapID with session mapID
        if LA.Session.GetCurrentSession("mapID") ~= GetBestMapForUnit("player") then
            LA.Debug.Log("  current vs. session mapID: %s vs. %s" , GetBestMapForUnit("player"), LA.Session.GetCurrentSession("mapID"))

            -- if we loot a noteworthy item we change the map id
            LA.Session.SetCurrentSession("mapID", GetBestMapForUnit("player"))
        end
    else
        LA.Debug.Log("  " .. tostring(itemID) .. ": gold value (" .. tostring(goldValue) .. ") < gold alert threshold (" .. gat .. ") -> no ding")
    end

    LA.UI.RefreshUIs()

    -- modules callback
    if not source and private.modules then
        for name, data in pairs(private.modules) do
            if data and data.callback and data.callback.itemDrop then
                local callback = data.callback.itemDrop

                callback(itemID, singleItemValue)
            end
        end
    end

    -- handle party loot
    if IsInGroup() and not source then
        private.SendAddonMsg(itemLink, itemID, quantity)
    end
end

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

-- get item value based on the selected/requested price source
function private.GetItemValue(itemID, priceSource)
	-- from which addon is our selected price source?
	if LA.Util.startsWith(LA.CONST.PRICE_SOURCE[LA.GetFromDb("pricesource", "source")], "TUJ:") then
		-- TUJ price source
		if priceSource == "VendorSell" then
			-- if we use TUJ and need 'VendorSell' we have to query the ItemInfo to get the price
			local vendorSell =  select(11, GetItemInfo(itemID)) or 0
			LA.Debug.Log("  GetItemValue: special handling for TUJ and pricesource 'VendorSell': " .. tostring(vendorSell))
			return vendorSell
		else
			local itemLink

			-- battle pet handling
			local newItemID = LA.PetData.ItemID2Species(itemID)
			if newItemID == itemID then
				itemLink = itemID
			else
				itemLink = newItemID
			end

			local priceInfo = {}
	    	TUJMarketInfo(itemLink, priceInfo)

			return priceInfo[priceSource]
		end
	else
		-- TSM price source
		return LA.TSM.GetItemValue(itemID, priceSource)
	end
end

-- handle looted currency
function private.HandleCurrencyLooted(lootedCopper)
	-- add to total looted currency
	--LA.Session.private.totalLootedCurrency = LA.Session.private.totalLootedCurrency + lootedCopper
	local totalLootedCurrency = (LA.Session.GetCurrentSession("totalLootedCurrency") or 0) + lootedCopper
	LA.Session.SetCurrentSession("totalLootedCurrency", totalLootedCurrency)

	LA.Debug.Log("  handle currency: add " .. tostring(lootedCopper) .. " copper -> new total: " .. tostring(totalLootedCurrency))

    LA.UI.RefreshUIs()
end

-- increase the noteworthy item counter
function private.IncNoteworthyItemCounter(quantity, source)
	if source then return end

	local noteworthyItemCounter = (LA.Session.GetCurrentSession("noteworthyItemCounter") or 0) + quantity
	LA.Session.SetCurrentSession("noteworthyItemCounter", noteworthyItemCounter)

	LA.Debug.Log("    noteworthy items counter: add " .. tostring(quantity) .. " -> new total: " .. tostring(noteworthyItemCounter))
end

-- increase the looted item counter
function private.IncLootedItemCounter(quantity, source)
	if source then return end

	local lootedItemCounter = (LA.Session.GetCurrentSession("lootedItemCounter") or 0) + quantity
	LA.Session.SetCurrentSession("lootedItemCounter", lootedItemCounter)

	LA.Debug.Log("    looted items counter: add " .. tostring(quantity) .. " -> new total: " .. tostring(lootedItemCounter))
end

-- add item value to looted item value and refresh ui
function private.AddItemValue2LootedItemValue(itemValue, source)
	local totalItemValue = LA.Session.GetCurrentSession("liv") or 0
	if not source then
		totalItemValue = totalItemValue + itemValue
		LA.Debug.Log("    looted items value: add " .. tostring(itemValue) .. " -> new total: " .. tostring(totalItemValue))
    end

    LA.Session.SetCurrentSession("liv", totalItemValue or 0)

    -- group
    local totalItemValueGroup = LA.Session.GetCurrentSession("livGroup") or 0
	totalItemValueGroup = totalItemValueGroup + itemValue
	LA.Debug.Log("    group: looted items value: add " .. tostring(itemValue) .. " -> new total: " .. tostring(totalItemValueGroup))
    LA.Session.SetCurrentSession("livGroup", totalItemValueGroup or 0)
end

--[[------------------------------------------------------------------------
-- checks if a item is blacklisted
--   check depends on the blacklist options (see config)
--------------------------------------------------------------------------]]
function LA.IsItemBlacklisted(itemID)
	--LA.Debug.Log("isItemBlacklisted(): itemID=" .. itemID)
	--LA.Debug.Log("  isBlacklistTsmGroupEnabled()=" .. tostring(private.IsBlacklistTsmGroupEnabled()))
	if not LA.GetFromDb("blacklist", "tsmGroupEnabled", "TSM_REQUIRED") then
		-- only use static list
		return LA.CONST.ITEM_FILTER_BLACKLIST[tostring(itemID)]
	end

	--local result = LA:isItemInList(itemID, blacklistItems)
	local result = LA.TSM.IsItemInGroup(itemID, LA.GetFromDb("blacklist", "tsmGroup"))
	--LA.Debug.Log("  isItemInList=" .. tostring(result))
	return result
end

-- get available price sources from the different modules
function private.GetAvailablePriceSources()
	local priceSources = {}

	-- TSM
	if LA.TSM.IsTSMLoaded() then
		priceSources = LA.TSM.GetAvailablePriceSources() or {}
	end

	-- TUJ
	if TUJMarketInfo then
		priceSources["globalMedian"] = "TUJ: Global Median"
		priceSources["globalMean"] = "TUJ: Global Mean"
		priceSources["globalStdDev"] = "TUJ: Global Std Dev"
		priceSources["stddev"] = "TUJ: 14-Day Std Dev"
		priceSources["market"] = "TUJ: 14-Day Price"
		priceSources["recent"] = "TUJ: 3-Day Price"
	end

	return priceSources
end


-- init lootappraiser db
function private.InitDB()
    LA.Debug.Log("InitDB")

    -- load the saved db values
    LA.db = LibStub:GetLibrary("AceDB-3.0"):New("LootAppraiserDB", LA.CONST.DB_DEFAULTS, true)
end

--[[--------------------------------------------------------------------------------------------------------------------
-- new
----------------------------------------------------------------------------------------------------------------------]]
function LA.GetFromDb(grp, key, ...)
	local tsmRequired
	for i = 1, select('#', ...) do
		local opt = select(i, ...)
		if opt == nil then
			-- do nothing
		elseif opt == "TSM_REQUIRED" then
			tsmRequired = true
		end
	end

	if tsmRequired and not LA.TSM.IsTSMLoaded() then
		return false
	end

    if LA.db.profile[grp][key] == nil then
        LA.db.profile[grp][key] = LA.CONST.DB_DEFAULTS.profile[grp][key]
    end
    return LA.db.profile[grp][key]
end

-- reset instance historie
local resetmsg = INSTANCE_RESET_SUCCESS:gsub("%%s",".+")
function private.OnResetInfoEvent(event, msg) --
    --if not LA.Session.IsRunning() then return end

    if event == "CHAT_MSG_SYSTEM" then
        if msg:match("^" .. resetmsg .. "$") then
            LA.Debug.Log("  match: " .. tostring(msg:match("^" .. resetmsg .. "$")))

            local instanceName = smatch(msg, INSTANCE_RESET_SUCCESS:gsub("%%s","(.+)"))

            local data = {["endTime"] = time() + 60*60, ["instanceName"] = instanceName}

			LA.UI.AddToResetInfo(data)
        end
    end
end

function LA.GetModules()
    return private.modules
end


-- legacy api for older LAC versions
function LA:RegisterModule(theModule)
    LA_API.RegisterModule(theModule)
end

LA.METADATA = {
    VERSION = "2018." .. LA_API.GetVersion()
}

LA.QUALITY_FILTER = LA.CONST.QUALITY_FILTER

LA.PRICE_SOURCE = LA.CONST.PRICE_SOURCE

function LA:tablelength(t)
    return LA.Util.tablelength(t)
end

function LA:print_r(t)
    LA.Debug.TableToString (t)
end

function LA:D(msg, ...)
    LA.Debug.Log(msg, ...)
end

function LA:getCurrentSession()
    return LA.Session.GetCurrentSession()
end

function LA:StartSession(showMainUI)
    LA.Session.Start(showMainUI)
end

function LA:ShowMainWindow(showMainUI)
    LA.UI.ShowMainWindow(showMainUI)
end

function LA:NewSession()
    LA.Session.New()
end

function LA:pauseSession()
    LA.Session.Pause()
end

function LA:refreshStatusText()
    LA.UI.RefreshStatusText()
end