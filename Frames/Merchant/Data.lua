-- Загрузка товаров торговца, выкупа и продажи из сумок.

local ConsoleMenu = _G.ConsoleMenu
local Merchant = ConsoleMenu.Merchant

-- Построить строку товара торговца.
function Merchant.BuildMerchantItemElement(item, isUnavailable)
    return {
        type = "merchantItem",
        isUnavailable = isUnavailable,
        slot = item.slot,
        itemID = item.itemID,
        name = item.name,
        texture = item.texture,
        price = item.price or 0,
        stackCount = item.stackCount,
        numAvailable = item.numAvailable,
        isPurchasable = item.isPurchasable,
        isUsable = item.isUsable,
        hasExtendedCost = item.hasExtendedCost,
        currencyID = item.currencyID,
        spellID = item.spellID,
        isQuestStartItem = item.isQuestStartItem,
    }
end

-- Построить строку предмета выкупа.
function Merchant.BuildBuybackItemElement(item)
    return {
        type = "buybackItem",
        isUnavailable = false,
        slot = item.slot,
        itemID = item.itemID,
        name = item.name,
        texture = item.texture,
        price = item.price or 0,
        stackCount = item.stackCount,
        numAvailable = item.numAvailable,
        isUsable = item.isUsable,
    }
end

-- Построить строку продажи из сумки.
function Merchant.BuildBagItemElement(item)
    return {
        type = "bagItem",
        isUnavailable = false,
        bag = item.bag,
        slot = item.slot,
        itemID = item.itemID,
        name = item.name,
        texture = item.texture,
        price = item.price or 0,
        stackCount = item.stackCount,
        quality = item.quality,
        classID = item.classID,
        needsItemInfo = item.needsItemInfo,
    }
end

-- Диапазон сумок персонажа: рюкзак, обычные сумки и сумка реагентов.
function Merchant.GetCharacterBagIndexRange()
    local firstBag = (Enum and Enum.BagIndex and Enum.BagIndex.Backpack) or 0
    local numBagSlots = (Constants and Constants.InventoryConstants and Constants.InventoryConstants.NumBagSlots) or NUM_BAG_SLOTS or 4
    local numReagentBagSlots = (Constants and Constants.InventoryConstants and Constants.InventoryConstants.NumReagentBagSlots) or NUM_REAGENTBAG_SLOTS or 1
    return firstBag, firstBag + numBagSlots + numReagentBagSlots
end

-- Серый предмет считается хламом для продажи торговцу.
function Merchant.IsJunkQuality(quality)
    local poorQuality = (Enum and Enum.ItemQuality and Enum.ItemQuality.Poor) or 0
    return quality == poorQuality
end

-- Запросить сведения о предмете, которые клиент ещё не отдал.
local function RequestSellItemInfo(itemID)
    if not itemID then
        return
    end
    Merchant.pendingSellItemIDs[itemID] = true
    if C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    end
end

-- Собрать товары торговца.
function Merchant.BuildTradeData()
    local merchantName = UnitName("npc") or UnitName("NPC") or "Торговец"
    local emptyTitle = merchantName .. " не может предложить товары на продажу"
    local emptyDescription = "Вы можете заняться продажей или выкупом предметов."
    local elements = {}

    local count = GetMerchantNumItems() or 0
    if count == 0 then
        return elements, emptyTitle, emptyDescription
    end

    local availableItems = {}
    local unavailableItems = {}

    for slot = 1, count do
        local info = C_MerchantFrame.GetItemInfo(slot)
        local itemID = GetMerchantItemID(slot)
        local isHeirloom = itemID and C_Heirloom.IsItemHeirloom(itemID)
        local isKnownHeirloom = isHeirloom and C_Heirloom.PlayerHasHeirloom(itemID)
        local hasTransmog = itemID and C_TransmogCollection.PlayerHasTransmogByItemInfo(itemID)

        if info then
            info.itemID = itemID
            info.slot = slot
            if not info.isPurchasable or (not info.isUsable and not isHeirloom) or info.numAvailable == 0 or isKnownHeirloom or hasTransmog then
                table.insert(unavailableItems, info)
            else
                table.insert(availableItems, info)
            end
        end
    end

    for _, item in ipairs(availableItems) do
        table.insert(elements, Merchant.BuildMerchantItemElement(item, false))
    end

    if #unavailableItems > 0 then
        table.insert(elements, {
            type = "separator",
            name = "Недоступные предметы",
        })
        for _, item in ipairs(unavailableItems) do
            table.insert(elements, Merchant.BuildMerchantItemElement(item, true))
        end
    end

    return elements, emptyTitle, emptyDescription
end

-- Собрать предметы выкупа.
function Merchant.BuildBuybackData()
    local emptyTitle = "Нет предметов для выкупа"
    local emptyDescription = "Продайте предмет торговцу, чтобы выкупить его позже."
    local elements = {}

    local count = GetNumBuybackItems() or 0
    for slot = 1, count do
        local name, texture, price, quantity, numAvailable, isUsable = GetBuybackItemInfo(slot)
        if name then
            local itemID = C_MerchantFrame.GetBuybackItemID and C_MerchantFrame.GetBuybackItemID(slot) or nil
            table.insert(elements, Merchant.BuildBuybackItemElement({
                slot = slot,
                itemID = itemID,
                name = name,
                texture = texture,
                price = price or 0,
                stackCount = quantity,
                numAvailable = numAvailable,
                isUsable = isUsable,
            }))
        end
    end

    return elements, emptyTitle, emptyDescription
end

-- Собрать продаваемые предметы из сумок персонажа.
function Merchant.BuildSellData()
    local emptyTitle = "Нет предметов для продажи"
    local emptyDescription = "В сумках нет вещей, которые этот торговец купит."
    local elements = {}

    wipe(Merchant.pendingSellItemIDs)

    local junkItems = {}
    local classGroups = {}
    local classOrder = {}
    local miscellaneousItems = {}

    local firstBag, lastBag = Merchant.GetCharacterBagIndexRange()
    for bag = firstBag, lastBag do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID and not info.hasNoValue and not info.isLocked then
                local isBattlePayItem = C_Container.IsBattlePayItem and C_Container.IsBattlePayItem(bag, slot)
                if not isBattlePayItem then
                    local _, _, _, _, _, instantClassID = C_Item.GetItemInfoInstant(info.itemID)
                    local itemName, _, _, _, _, _, _, _, _, _, sellPrice, infoClassID = C_Item.GetItemInfo(info.itemID)
                    local classID = infoClassID or instantClassID
                    local stackCount = info.stackCount or 1
                    local displayName = info.itemName or itemName or ""
                    local needsItemInfo = sellPrice == nil or displayName == ""
                    if needsItemInfo then
                        RequestSellItemInfo(info.itemID)
                    end

                    local totalPrice = 0
                    if sellPrice and sellPrice > 0 then
                        totalPrice = sellPrice * stackCount
                    end

                    local item = {
                        bag = bag,
                        slot = slot,
                        itemID = info.itemID,
                        name = displayName,
                        texture = info.iconFileID,
                        price = totalPrice,
                        stackCount = stackCount,
                        quality = info.quality,
                        classID = classID,
                        needsItemInfo = needsItemInfo,
                    }

                    if Merchant.IsJunkQuality(info.quality) then
                        table.insert(junkItems, item)
                    elseif classID then
                        if not classGroups[classID] then
                            classGroups[classID] = {}
                            table.insert(classOrder, classID)
                        end
                        table.insert(classGroups[classID], item)
                    else
                        table.insert(miscellaneousItems, item)
                    end
                end
            end
        end
    end

    table.sort(classOrder)

    local function InsertSellGroup(title, items)
        if not items or #items == 0 then
            return
        end
        table.insert(elements, {
            type = "separator",
            name = title,
        })
        for _, item in ipairs(items) do
            table.insert(elements, Merchant.BuildBagItemElement(item))
        end
    end

    InsertSellGroup("Хлам", junkItems)
    for _, classID in ipairs(classOrder) do
        local className = C_Item.GetItemClassInfo(classID)
        InsertSellGroup(className ~= "" and className or "Разное", classGroups[classID])
    end
    InsertSellGroup("Разное", miscellaneousItems)

    return elements, emptyTitle, emptyDescription
end

-- Данные выбранной вкладки: строки и тексты пустого списка.
function Merchant.BuildTabData(tab)
    if not tab then
        return {}, "", ""
    end
    if tab.code == "trade" then
        return Merchant.BuildTradeData()
    end
    if tab.code == "sell" then
        return Merchant.BuildSellData()
    end
    if tab.code == "buyback" then
        return Merchant.BuildBuybackData()
    end
    return {}, "", ""
end

-- Обработать догрузку сведений о предмете на вкладке продажи.
function Merchant.OnItemInfoReceived(itemID)
    if not itemID or not Merchant.pendingSellItemIDs[itemID] then
        return false
    end
    Merchant.pendingSellItemIDs[itemID] = nil
    local tab = Merchant.tabs[Merchant.focusedTabIndex]
    return tab and tab.code == "sell"
end
