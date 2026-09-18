-- Запас подсказок, текст описания и предел пачки с догрузкой соседних строк.

local ConsoleMenu = _G.ConsoleMenu
local Merchant = ConsoleMenu.Merchant

local tooltipDataCache = {}
local tooltipInstanceMap = {}
local stackSizeDataCache = {}

-- Ключ запаса по типу строки, сумке и ячейке.
function Merchant.GetCacheKey(itemType, slot, bag)
    if not itemType or not slot then
        return nil
    end
    if bag ~= nil then
        return itemType .. ":" .. tostring(bag) .. ":" .. tostring(slot)
    end
    return itemType .. ":" .. tostring(slot)
end

-- Ключ запаса по данным строки списка.
function Merchant.GetElementCacheKey(element)
    if not element then
        return nil
    end
    return Merchant.GetCacheKey(element.type, element.slot, element.bag)
end

-- Сбросить запас подсказок.
function Merchant.ClearTooltipCache()
    wipe(tooltipDataCache)
    wipe(tooltipInstanceMap)
end

-- Сбросить запас пределов пачки.
function Merchant.ClearStackSizeCache()
    wipe(stackSizeDataCache)
end

-- Сбросить выбор и запасы при закрытии торговца.
function Merchant.ResetSelection()
    Merchant.focusedTabIndex = 1
    Merchant.tabFocus = {}
    Merchant.ClearTooltipCache()
    Merchant.ClearStackSizeCache()
    wipe(Merchant.pendingSellItemIDs)
    local list = Merchant.GetList()
    if list then
        list.focusedIndex = 1
        list.focusedExtent = ConsoleMenu.ExpandableList.sectionHeight
        list:Clear()
    end
end

-- Целое число покупок, которое можно оплатить данной ценой.
local function AffordableCount(owned, costValue, stackCount, maxStack)
    if not costValue or costValue <= 0 or not stackCount or stackCount <= 0 then
        return maxStack
    end
    return math.floor((owned * stackCount) / costValue)
end

-- Количество валюты по ссылке или по имени у текущего торговца.
local function GetOwnedCurrencyCount(costLink, currencyName)
    if costLink and C_CurrencyInfo.GetCurrencyInfoFromLink then
        local info = C_CurrencyInfo.GetCurrencyInfoFromLink(costLink)
        if info and info.quantity then
            return info.quantity
        end
    end

    if not currencyName then
        return nil
    end

    local merchantCurrencyIDs = nil
    if C_MerchantFrame.GetMerchantCurrencies then
        merchantCurrencyIDs = C_MerchantFrame.GetMerchantCurrencies()
    end
    if merchantCurrencyIDs then
        for index = 1, #merchantCurrencyIDs do
            local currencyID = merchantCurrencyIDs[index]
            local info = currencyID and C_CurrencyInfo.GetCurrencyInfo(currencyID)
            if info and info.name == currencyName then
                return info.quantity or 0
            end
        end
    end

    return nil
end

-- Сколько предметов можно купить за одну операцию с учётом золота, предметов и валют.
function Merchant.GetAffordablePurchaseCount(slot, maxStack)
    if not slot or not maxStack or maxStack <= 1 then
        return 1
    end

    local canAfford = maxStack
    local info = C_MerchantFrame.GetItemInfo(slot)
    local stackCount = (info and info.stackCount) or 1

    if info and info.price and info.price > 0 then
        canAfford = math.min(canAfford, AffordableCount(GetMoney(), info.price, stackCount, maxStack))
    end

    if info and info.hasExtendedCost then
        local itemCount = GetMerchantItemCostInfo(slot) or 0
        for costIndex = 1, math.min(Merchant.maxItemCost, itemCount) do
            local _, itemValue, itemLink, currencyName = GetMerchantItemCostItem(slot, costIndex)
            if itemValue and itemValue > 0 then
                local owned = nil
                local currencyCount = GetOwnedCurrencyCount(itemLink, currencyName)
                if currencyCount ~= nil then
                    owned = currencyCount
                elseif itemLink then
                    owned = C_Item.GetItemCount(itemLink, false, false, true)
                end
                if owned then
                    canAfford = math.min(canAfford, AffordableCount(owned, itemValue, stackCount, maxStack))
                end
            end
        end
    end

    if canAfford < 1 then
        return 1
    end

    return math.min(maxStack, canAfford)
end

-- Предел пачки у торговца. Неготовое значение не запоминается.
function Merchant.GetListItemStackSize(element)
    if not element or not element.slot or element.type ~= "merchantItem" then
        return 1
    end

    local cacheKey = Merchant.GetElementCacheKey(element)
    local maxStack = cacheKey and stackSizeDataCache[cacheKey]
    if not maxStack then
        maxStack = GetMerchantItemMaxStack(element.slot)
        if not maxStack or maxStack < 1 then
            return 1
        end
        if cacheKey then
            stackSizeDataCache[cacheKey] = maxStack
        end
    end

    if maxStack <= 1 then
        return 1
    end

    return Merchant.GetAffordablePurchaseCount(element.slot, maxStack)
end

-- Запросить подсказку товара, выкупа или предмета из сумки.
function Merchant.GetListItemTooltipData(element, forceRefresh)
    if not element or not element.slot or not Merchant.IsListItem(element) then
        return nil
    end

    local cacheKey = Merchant.GetElementCacheKey(element)
    if not forceRefresh and cacheKey then
        local cached = tooltipDataCache[cacheKey]
        if cached then
            return cached.tooltipData
        end
    end

    local tooltipData
    if element.type == "merchantItem" then
        tooltipData = C_TooltipInfo.GetMerchantItem(element.slot)
    elseif element.type == "buybackItem" then
        tooltipData = C_TooltipInfo.GetBuybackItem(element.slot)
    elseif element.type == "bagItem" and element.bag ~= nil then
        tooltipData = C_TooltipInfo.GetBagItem(element.bag, element.slot)
    end

    if cacheKey then
        local previous = tooltipDataCache[cacheKey]
        if previous and previous.instanceID then
            tooltipInstanceMap[previous.instanceID] = nil
        end

        local instanceID = tooltipData and tooltipData.dataInstanceID or nil
        local lines = tooltipData and tooltipData.lines
        local isComplete = lines and #lines > 1

        if tooltipData then
            tooltipDataCache[cacheKey] = {
                tooltipData = tooltipData,
                instanceID = instanceID,
                isComplete = isComplete,
            }
            if instanceID then
                tooltipInstanceMap[instanceID] = cacheKey
            end
        elseif forceRefresh then
            tooltipDataCache[cacheKey] = nil
        end
    end

    return tooltipData
end

-- Окрасить фрагмент текста подсказки.
local function ColorizeTooltipText(text, color)
    if not text or not color then
        return text
    end

    local r = math.floor((color.r or 0.9) * 255 + 0.5)
    local g = math.floor((color.g or 0.9) * 255 + 0.5)
    local b = math.floor((color.b or 0.9) * 255 + 0.5)
    return string.format("|cff%02x%02x%02x%s|r", r, g, b, text)
end

-- Собрать короткое описание из подсказки, без цены продажи.
function Merchant.BuildTooltipDescriptionText(tooltipData)
    local tooltipLines = tooltipData and tooltipData.lines
    if not tooltipLines then
        return nil
    end

    local sellPriceLineType = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.SellPrice
    local parts = {}
    local added = 0

    for tooltipLineIndex = 2, #tooltipLines do
        if added >= Merchant.maxTooltipDescriptionLines then
            break
        end

        local tooltipLine = tooltipLines[tooltipLineIndex]
        if tooltipLine and not (sellPriceLineType and tooltipLine.type == sellPriceLineType) then
            local leftText = tooltipLine.leftText
            local containsAngleBrackets = leftText and leftText:find("<", 1, true) and leftText:find(">", 1, true)
            if leftText and leftText ~= "" and not containsAngleBrackets then
                local displayText = ColorizeTooltipText(leftText, tooltipLine.leftColor) or leftText
                local rightText = tooltipLine.rightText
                if rightText and rightText ~= "" then
                    displayText = displayText .. ", " .. (ColorizeTooltipText(rightText, tooltipLine.rightColor) or rightText)
                end
                table.insert(parts, displayText)
                added = added + 1
            end
        end
    end

    if #parts == 0 then
        return nil
    end

    return table.concat(parts, "\n")
end

-- Текст цены и значки дополнительного блока раскрытой строки.
function Merchant.GetExpandPrice(data)
    if not data or data.isUnavailable or not Merchant.IsListItem(data) then
        return nil, nil
    end

    local extraIcons = {}
    local costCount = 0
    if data.type == "merchantItem" and data.slot then
        costCount = GetMerchantItemCostInfo(data.slot) or 0
    end

    if costCount > 0 and data.slot then
        local costParts = {}
        for costIndex = 1, costCount do
            local costTexture, costValue, costLink, currencyName = GetMerchantItemCostItem(data.slot, costIndex)
            if costValue and costValue > 0 then
                local costName = currencyName
                if not costName and costLink then
                    local itemName = C_Item.GetItemInfo(costLink)
                    costName = itemName or costLink
                end
                table.insert(costParts, {
                    name = (costName and costName ~= "") and costName or "Валюта",
                    value = costValue,
                    texture = costTexture,
                })
                if costTexture and costTexture ~= 0 and #extraIcons < 2 then
                    table.insert(extraIcons, costTexture)
                end
            end
        end

        local formattedCostParts = {}
        for _, costPart in ipairs(costParts) do
            table.insert(formattedCostParts, string.format("%s x%d", costPart.name, costPart.value))
        end
        if data.price and data.price > 0 then
            table.insert(formattedCostParts, GetMoneyString(data.price, true))
        end
        if #formattedCostParts > 0 then
            return table.concat(formattedCostParts, ", "), extraIcons
        end
        return nil, extraIcons
    end

    if data.price and data.price > 0 then
        return GetMoneyString(data.price, true), extraIcons
    end

    return nil, extraIcons
end

-- Описание, заголовок и цена для раскрытия строки списка.
function Merchant.GetExpandInfo(data)
    local title = data and data.name or ""
    if data and data.stackCount and data.stackCount > 1 then
        title = string.format("%s x%d", data.name, data.stackCount)
    end

    local tooltipData = Merchant.GetListItemTooltipData(data)
    local extraText, extraIcons = Merchant.GetExpandPrice(data)
    return {
        title = title,
        description = Merchant.BuildTooltipDescriptionText(tooltipData),
        extraText = extraText,
        extraIcons = extraIcons,
    }
end

-- Подгрузить подсказки выбранной строки и соседей.
function Merchant.LoadNearTooltipData(element)
    local list = Merchant.GetList()
    if not element or not Merchant.IsListItem(element) or not list then
        return
    end

    Merchant.GetListItemTooltipData(element)
    for _, neighbor in ipairs(list:GetNeighbors(element)) do
        Merchant.GetListItemTooltipData(neighbor)
    end
end

-- Подгрузить пределы пачки выбранной строки и соседей.
function Merchant.LoadNearStackSizeData(element)
    local list = Merchant.GetList()
    if not element or element.type ~= "merchantItem" or not list then
        return
    end

    Merchant.GetListItemStackSize(element)
    for _, neighbor in ipairs(list:GetNeighbors(element)) do
        if neighbor.type == "merchantItem" then
            Merchant.GetListItemStackSize(neighbor)
        end
    end
end

-- Подгрузить сведения вокруг выбранной или первой строки.
function Merchant.PreloadNearFocusedOrFirst()
    local list = Merchant.GetList()
    if not list then
        return
    end

    local target = list:GetFocusedElement()
    if not target or not Merchant.IsListItem(target) then
        target = list:FindElement(function(element)
            return Merchant.IsListItem(element)
        end)
    end
    if not target then
        return
    end

    Merchant.LoadNearTooltipData(target)
    if target.type == "merchantItem" then
        Merchant.LoadNearStackSizeData(target)
    end
end

-- Сбросить запас по экземпляру подсказки и перерисовать выбранную строку.
function Merchant.OnTooltipDataUpdate(dataInstanceID)
    if dataInstanceID then
        local cacheKey = tooltipInstanceMap[dataInstanceID]
        if not cacheKey then
            return
        end
        tooltipInstanceMap[dataInstanceID] = nil
        tooltipDataCache[cacheKey] = nil
    else
        local list = Merchant.GetList()
        local element = list and list:GetFocusedElement()
        if element and Merchant.IsListItem(element) then
            local cacheKey = Merchant.GetElementCacheKey(element)
            local cached = cacheKey and tooltipDataCache[cacheKey]
            if cached then
                if cached.instanceID then
                    tooltipInstanceMap[cached.instanceID] = nil
                end
                tooltipDataCache[cacheKey] = nil
            end
            for _, neighbor in ipairs(list:GetNeighbors(element)) do
                local neighborKey = Merchant.GetElementCacheKey(neighbor)
                local neighborCached = neighborKey and tooltipDataCache[neighborKey]
                if neighborCached then
                    if neighborCached.instanceID then
                        tooltipInstanceMap[neighborCached.instanceID] = nil
                    end
                    tooltipDataCache[neighborKey] = nil
                end
            end
        end
    end

    local list = Merchant.GetList()
    local element = list and list:GetFocusedElement()
    if not element or not Merchant.IsListItem(element) then
        return
    end

    if Merchant.tooltipRefreshQueued then
        return
    end

    Merchant.tooltipRefreshQueued = true
    C_Timer.After(0, function()
        Merchant.tooltipRefreshQueued = false
        local focusedList = Merchant.GetList()
        local focusedElement = focusedList and focusedList:GetFocusedElement()
        if not focusedElement or not Merchant.IsListItem(focusedElement) then
            return
        end
        Merchant.LoadNearTooltipData(focusedElement)
        focusedList:RefreshFocused()
    end)
end
