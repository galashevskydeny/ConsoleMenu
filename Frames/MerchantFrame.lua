local ConsoleMenu = _G.ConsoleMenu

local dataProvider

local frameWidth = 480
local frameLeftOffset = 34
local contentPadding = 38

local sectionHeight = 80
local sectionPadding = 10
local unfocusedItemTextAlpha = 0.6

local iconSize = sectionHeight - sectionPadding * 2

local emptyListFontSize = 32
local emptyListDescriptionFontSize = 20

local itemFontSize = 18
local focusedItemFontSize = itemFontSize + 2
local descriptionFontSize = 14
local tabFontSize = 22
local maxTooltipDescriptionLines = 20

-- Максимум дополнительных цен у одного товара в эталоне клиента.
local maxItemCost = 3

local focusedTabIndex = 1
local tabs = {}
local merchantTabSlotCount = 3

local currencyIconSize = 20
local currencyIconOverlap = currencyIconSize / 4
local currencyIconDualHeight = currencyIconSize * 2 - currencyIconOverlap

local focusedIndex = 1
local focusedSlot = nil
local focusedBag = nil
local focusedItemType = nil
local lastFocusedSlot = nil
local lastFocusedBag = nil
local lastFocusedType = nil
local lastFocusedIndex = 1
local focusedItemExtent = sectionHeight

-- Запас подсказок и пределов пачки: ключ — тип пункта и номер.
local itemListTooltipDataCache = {}
local itemListTooltipInstanceMap = {}
local itemListStackSizeDataCache = {}

local merchantRefreshQueued = false
local merchantRefreshRebuildTabs = false
local tooltipRefreshQueued = false
local pendingOverrideBindings = false
local pendingClearOverrideBindings = false
local moneyEventsRegistered = false

local animationDuration = 0.1

local itemListBackgroundVOffset = 640
local itemListBackgroundHOffset = 440

local currenciesData = {}

local currenciesWidth = 304
local currenciesSectionHeight = 32

local currenciesMaxItems = 3
local currenciesHeight = currenciesSectionHeight * currenciesMaxItems

local currenciesIconSize = currenciesSectionHeight
local currenciesIconInnerPadding = 8
local currenciesFontSize = 16

-- Функция для перепривязки фона списка предметов
local function ReanchorItemListBackground(countItems)
    local itemListFrame = ConsoleMenuFrame and ConsoleMenuFrame.ItemListFrame
    if not itemListFrame or not itemListFrame.Background then
        return
    end

    if not itemListFrame.AdditionalShadow then
        return
    end

    local background = itemListFrame.Background
    local additionalShadow = itemListFrame.AdditionalShadow
    local anchorFrame = itemListFrame

    if countItems and countItems > 0 then
        anchorFrame = itemListFrame.Items or itemListFrame
    else
        anchorFrame = itemListFrame.EmptyList or itemListFrame
    end

    background:ClearAllPoints()

    background:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", -itemListBackgroundHOffset * 1.5, itemListBackgroundVOffset)
    background:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", itemListBackgroundHOffset, itemListBackgroundVOffset)
    background:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMLEFT", -itemListBackgroundHOffset * 1.5, -itemListBackgroundVOffset)
    background:SetPoint("BOTTOMRIGHT", anchorFrame, "BOTTOMRIGHT", itemListBackgroundHOffset, -itemListBackgroundVOffset)

    additionalShadow:ClearAllPoints()
    additionalShadow:SetPoint("TOP", anchorFrame, "TOP", 0, itemListBackgroundVOffset * 1.2)
    additionalShadow:SetPoint("BOTTOM", anchorFrame, "BOTTOM", 0, -itemListBackgroundVOffset * 1.2)
    additionalShadow:SetPoint("RIGHT", anchorFrame, "CENTER", itemListBackgroundHOffset / 2, 0)
end

-- Функция для обновления отображения списка предметов
local function RefreshItemListScrollLayout()
    local itemListFrame = ConsoleMenuFrame and ConsoleMenuFrame.ItemListFrame
    local scrollBox = itemListFrame and itemListFrame.Items and itemListFrame.Items.ScrollBox
    if not scrollBox then
        return
    end

    if scrollBox.FullUpdate then
        if ScrollBoxConstants and ScrollBoxConstants.UpdateImmediately then
            scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately)
        else
            scrollBox:FullUpdate()
        end
    elseif scrollBox.Update then
        scrollBox:Update()
    end
end

-- Обновить скроллбар и горизонтальный отступ списка
local function UpdateItemsScrollBarLayout()
    local itemListFrame = ConsoleMenuFrame and ConsoleMenuFrame.ItemListFrame
    local items = itemListFrame and itemListFrame.Items
    local scrollBox = items and items.ScrollBox
    local scrollBar = items and items.ScrollBar
    if not scrollBox then
        return
    end

    RefreshItemListScrollLayout()

    if not scrollBar then
        return
    end

    local scrollRange = scrollBox:GetDerivedScrollRange() or 0
    if scrollRange > 0 then
        scrollBar:Show()
    else
        scrollBar:Hide()
    end
end

-- Товар, выкуп или предмет из сумки — обычная строка списка, не разделитель.
local function IsListItemType(itemType)
    return itemType == "merchantItem" or itemType == "buybackItem" or itemType == "bagItem"
end

-- Совпадает ли пункт с текущим фокусом, учитывая сумку для продажи.
local function IsFocusedListElement(elementData)
    if not elementData or not IsListItemType(elementData.type) then
        return false
    end
    if not focusedSlot or focusedItemType ~= elementData.type then
        return false
    end
    if elementData.type == "bagItem" then
        return elementData.slot == focusedSlot and elementData.bag == focusedBag
    end
    return elementData.slot == focusedSlot
end

-- Высота строки списка: выделенный товар может быть выше остальных.
local function GetItemListElementExtent(elementData)
    if IsFocusedListElement(elementData) then
        return math.max(sectionHeight, focusedItemExtent or sectionHeight)
    end

    return sectionHeight
end

-- Ключ запаса сведений по типу пункта, сумке и номеру ячейки.
local function GetCacheKey(itemType, slot, bag)
    if not itemType or not slot then
        return nil
    end
    if bag ~= nil then
        return itemType .. ":" .. tostring(bag) .. ":" .. tostring(slot)
    end
    return itemType .. ":" .. tostring(slot)
end

-- Ключ запаса по данным пункта списка.
local function GetElementCacheKey(element)
    if not element then
        return nil
    end
    return GetCacheKey(element.type, element.slot, element.bag)
end

-- Сбросить запас подсказок.
local function ClearItemListTooltipDataCache()
    wipe(itemListTooltipDataCache)
    wipe(itemListTooltipInstanceMap)
end

-- Сбросить запас пределов пачки.
local function ClearItemListStackSizeDataCache()
    wipe(itemListStackSizeDataCache)
end

-- Полный сброс выбора и запасов при закрытии торговца.
local function ResetMerchantSelection()
    focusedIndex = 1
    focusedSlot = nil
    focusedBag = nil
    focusedItemType = nil
    lastFocusedSlot = nil
    lastFocusedBag = nil
    lastFocusedType = nil
    lastFocusedIndex = 1
    focusedItemExtent = sectionHeight
    ClearItemListTooltipDataCache()
    ClearItemListStackSizeDataCache()
end

-- Обновить фокус на пункте списка.
local function UpdateFocus(element, changeFocus)
    if not element then
        return
    end

    local frame = ConsoleMenuFrame and ConsoleMenuFrame.ItemListFrame
    if not frame or not frame.Items or not frame.Items.ScrollBox then
        return
    end

    local scrollBox = frame.Items.ScrollBox
    local layoutChanged = false
    local previousExtent = focusedItemExtent

    focusedIndex = scrollBox:FindElementDataIndex(element)
    if not focusedIndex then
        return
    end

    local nextSlot = IsListItemType(element.type) and element.slot or nil
    local nextType = IsListItemType(element.type) and element.type or nil
    local nextBag = element.type == "bagItem" and element.bag or nil
    local slotChanged = nextSlot ~= focusedSlot or nextType ~= focusedItemType or nextBag ~= focusedBag
    if slotChanged then
        focusedItemExtent = sectionHeight
    end
    focusedSlot = nextSlot
    focusedBag = nextBag
    focusedItemType = nextType
    lastFocusedSlot = nextSlot
    lastFocusedBag = nextBag
    lastFocusedType = nextType
    lastFocusedIndex = focusedIndex

    if changeFocus then
        scrollBox:ScrollToElementDataIndex(focusedIndex)
    end

    for _, listItemFrame in ipairs(scrollBox:GetFrames()) do
        if listItemFrame.SetFocused then
            layoutChanged = listItemFrame:SetFocused(false) or layoutChanged
        end
    end

    local focusedFrame = scrollBox:FindFrameByPredicate(function(listItemFrame, elementData)
        return elementData == element
    end)

    if focusedFrame and focusedFrame.SetFocused then
        layoutChanged = focusedFrame:SetFocused(true) or layoutChanged
    end

    if layoutChanged or focusedItemExtent ~= previousExtent then
        UpdateItemsScrollBarLayout()
    end
end

-- Текущий пункт по индексу фокуса.
local function GetFocusedElement()
    if not dataProvider or not dataProvider.collection then
        return nil
    end
    return dataProvider.collection[focusedIndex]
end

-- Перерисовать выделенную строку после догрузки подсказки.
local function RefreshFocusedItemFrame()
    local element = GetFocusedElement()
    if not element then
        return
    end
    UpdateFocus(element, false)
end

-- Сколько предметов можно купить за одну операцию, с учётом золота и дополнительной цены.
local function GetAffordablePurchaseCount(slot, maxStack)
    if not slot or not maxStack or maxStack <= 1 then
        return 1
    end

    local canAfford = maxStack
    local info = C_MerchantFrame.GetItemInfo(slot)
    if info and info.price and info.price > 0 and info.stackCount and info.stackCount > 0 then
        canAfford = math.floor(GetMoney() / (info.price / info.stackCount))
    end

    if info and info.hasExtendedCost then
        local itemCount = GetMerchantItemCostInfo(slot) or 0
        for costIndex = 1, maxItemCost do
            if costIndex > itemCount then
                break
            end
            local _, itemValue, itemLink, currencyName = GetMerchantItemCostItem(slot, costIndex)
            if itemLink and not currencyName and itemValue and itemValue > 0 and info.stackCount and info.stackCount > 0 then
                local myCount = C_Item.GetItemCount(itemLink, false, false, true)
                canAfford = math.min(canAfford, math.floor(myCount / (itemValue / info.stackCount)))
            end
        end
    end

    if canAfford < 1 then
        return 1
    end

    return math.min(maxStack, canAfford)
end

-- Предел пачки у торговца. Неготовое значение не запоминается.
local function GetListItemStackSize(element)
    if not element or not element.slot then
        return 1
    end

    if element.type ~= "merchantItem" then
        return 1
    end

    local cacheKey = GetElementCacheKey(element)
    local cachedMaxStack = cacheKey and itemListStackSizeDataCache[cacheKey]
    local maxStack = cachedMaxStack

    if not maxStack then
        maxStack = GetMerchantItemMaxStack(element.slot)
        if not maxStack or maxStack < 1 then
            return 1
        end
        if cacheKey then
            itemListStackSizeDataCache[cacheKey] = maxStack
        end
    end

    if maxStack <= 1 then
        return 1
    end

    return GetAffordablePurchaseCount(element.slot, maxStack)
end

-- Запросить подсказку товара, выкупа или предмета из сумки. Неполный снимок можно показать, но не запирать.
local function GetListItemTooltipData(element, forceRefresh)
    if not element or not element.slot or not IsListItemType(element.type) then
        return nil
    end

    local cacheKey = GetElementCacheKey(element)
    if not forceRefresh and cacheKey then
        local cached = itemListTooltipDataCache[cacheKey]
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
        local previous = itemListTooltipDataCache[cacheKey]
        if previous and previous.instanceID then
            itemListTooltipInstanceMap[previous.instanceID] = nil
        end

        local instanceID = tooltipData and tooltipData.dataInstanceID or nil
        local lines = tooltipData and tooltipData.lines
        local isComplete = lines and #lines > 1

        if tooltipData then
            itemListTooltipDataCache[cacheKey] = {
                tooltipData = tooltipData,
                instanceID = instanceID,
                isComplete = isComplete,
            }
            if instanceID then
                itemListTooltipInstanceMap[instanceID] = cacheKey
            end
        elseif forceRefresh then
            itemListTooltipDataCache[cacheKey] = nil
        end
    end

    return tooltipData
end

-- Найти пункт списка по типу, ячейке и сумке. Без заглушки: только реальные строки.
local function FindListItemElementBySlot(slot, itemType, bag)
    if not dataProvider or not dataProvider.collection or not slot then
        return nil
    end

    for _, element in ipairs(dataProvider.collection) do
        if element.type ~= "separator" and element.slot == slot then
            if not itemType or element.type == itemType then
                if itemType == "bagItem" then
                    if element.bag == bag then
                        return element
                    end
                else
                    return element
                end
            end
        end
    end

    return nil
end

-- Найти ближайший предмет списка начиная с сохранённого номера строки.
local function FindNearestListItemElement(startIndex)
    if not dataProvider or not dataProvider.collection then
        return nil
    end

    local size = #dataProvider.collection
    if size == 0 then
        return nil
    end

    local fromIndex = startIndex or 1
    if fromIndex < 1 then
        fromIndex = 1
    elseif fromIndex > size then
        fromIndex = size
    end

    for i = fromIndex, size do
        local element = dataProvider.collection[i]
        if element and IsListItemType(element.type) then
            return element
        end
    end

    for i = fromIndex - 1, 1, -1 do
        local element = dataProvider.collection[i]
        if element and IsListItemType(element.type) then
            return element
        end
    end

    return nil
end

-- Соседи в списке относительно выбранного пункта, минуя разделители.
local function GetNeighborElements(element)
    local neighbors = {}
    if not dataProvider or not dataProvider.collection or not element then
        return neighbors
    end

    local index = nil
    for i, candidate in ipairs(dataProvider.collection) do
        if candidate == element then
            index = i
            break
        end
    end
    if not index then
        return neighbors
    end

    local function FindNeighbor(startIndex, step)
        local i = startIndex
        while dataProvider.collection[i] do
            local neighbor = dataProvider.collection[i]
            if IsListItemType(neighbor.type) then
                return neighbor
            end
            i = i + step
        end
        return nil
    end

    local previousElement = FindNeighbor(index - 1, -1)
    local nextElement = FindNeighbor(index + 1, 1)
    if previousElement then
        table.insert(neighbors, previousElement)
    end
    if nextElement then
        table.insert(neighbors, nextElement)
    end

    return neighbors
end

-- Подгрузить подсказки выбранного пункта и соседей.
local function LoadNearItemListTooltipData(element)
    if not element or not IsListItemType(element.type) then
        return
    end

    GetListItemTooltipData(element)

    for _, neighbor in ipairs(GetNeighborElements(element)) do
        GetListItemTooltipData(neighbor)
    end
end

-- Подгрузить пределы пачки выбранного пункта и соседей.
local function LoadNearItemListStackSizeData(element)
    if not element or element.type ~= "merchantItem" then
        return
    end

    GetListItemStackSize(element)

    for _, neighbor in ipairs(GetNeighborElements(element)) do
        if neighbor.type == "merchantItem" then
            GetListItemStackSize(neighbor)
        end
    end
end

-- Догрузка строк подсказки с сервера: сопоставить экземпляр и перерисовать.
local function OnTooltipDataUpdate(dataInstanceID)
    if dataInstanceID then
        local cacheKey = itemListTooltipInstanceMap[dataInstanceID]
        if not cacheKey then
            return
        end
        itemListTooltipInstanceMap[dataInstanceID] = nil
        itemListTooltipDataCache[cacheKey] = nil
    else
        local element = GetFocusedElement()
        if element and IsListItemType(element.type) then
            local cacheKey = GetElementCacheKey(element)
            local cached = cacheKey and itemListTooltipDataCache[cacheKey]
            if cached then
                if cached.instanceID then
                    itemListTooltipInstanceMap[cached.instanceID] = nil
                end
                itemListTooltipDataCache[cacheKey] = nil
            end
            for _, neighbor in ipairs(GetNeighborElements(element)) do
                local neighborKey = GetElementCacheKey(neighbor)
                local neighborCached = neighborKey and itemListTooltipDataCache[neighborKey]
                if neighborCached then
                    if neighborCached.instanceID then
                        itemListTooltipInstanceMap[neighborCached.instanceID] = nil
                    end
                    itemListTooltipDataCache[neighborKey] = nil
                end
            end
        end
    end

    local element = GetFocusedElement()
    if not element or not IsListItemType(element.type) then
        return
    end

    if tooltipRefreshQueued then
        return
    end

    tooltipRefreshQueued = true
    C_Timer.After(0, function()
        tooltipRefreshQueued = false
        local focusedElement = GetFocusedElement()
        if not focusedElement or not IsListItemType(focusedElement.type) then
            return
        end

        LoadNearItemListTooltipData(focusedElement)
        RefreshFocusedItemFrame()
    end)
end

-- Нужно ли чинить снаряжение у этого торговца.
local function NeedsEquipmentRepair()
    if not CanMerchantRepair() then
        return false
    end

    local repairCost, canRepair = GetRepairAllCost()
    if canRepair then
        return true
    end

    return repairCost and repairCost > 0
end

-- Можно ли продать весь хлам у этого торговца.
local function CanSellAllJunk()
    if not C_MerchantFrame.IsSellAllJunkEnabled or not C_MerchantFrame.GetNumJunkItems then
        return false
    end
    if not C_MerchantFrame.IsSellAllJunkEnabled() then
        return false
    end
    local numJunkItems = C_MerchantFrame.GetNumJunkItems()
    return numJunkItems and numJunkItems > 0
end

-- Подсказки кнопок для выбранного пункта и текущей вкладки.
local function UpdateMerchantActionKeys(element)
    local tab = tabs[focusedTabIndex]
    local canRepair = tab and tab.code == "trade" and NeedsEquipmentRepair()
    local canSellAllJunk = tab and tab.code == "sell" and CanSellAllJunk()

    if element and element.type == "merchantItem" and not element.isUnavailable then
        ConsoleMenu:AddKeysFrameItem("PAD1", "Купить предмет")
        if canRepair then
            ConsoleMenu:AddKeysFrameItem("PAD3", "Отремонтировать снаряжение")
        else
            ConsoleMenu:DeleteKeysFrameItem("PAD3")
        end
        if GetListItemStackSize(element) > 1 then
            ConsoleMenu:AddKeysFrameItem("PAD4", "Купить пачку предметов")
        else
            ConsoleMenu:DeleteKeysFrameItem("PAD4")
        end
    elseif element and element.type == "buybackItem" then
        ConsoleMenu:AddKeysFrameItem("PAD1", "Выкупить предмет")
        ConsoleMenu:DeleteKeysFrameItem("PAD3")
        ConsoleMenu:DeleteKeysFrameItem("PAD4")
    elseif element and element.type == "bagItem" then
        ConsoleMenu:AddKeysFrameItem("PAD1", "Продать предмет")
        ConsoleMenu:DeleteKeysFrameItem("PAD3")
        if canSellAllJunk then
            ConsoleMenu:AddKeysFrameItem("PAD4", "Продать весь хлам")
        else
            ConsoleMenu:DeleteKeysFrameItem("PAD4")
        end
    else
        ConsoleMenu:DeleteKeysFrameItem("PAD1")
        if canRepair then
            ConsoleMenu:AddKeysFrameItem("PAD3", "Отремонтировать снаряжение")
        else
            ConsoleMenu:DeleteKeysFrameItem("PAD3")
        end
        if canSellAllJunk then
            ConsoleMenu:AddKeysFrameItem("PAD4", "Продать весь хлам")
        else
            ConsoleMenu:DeleteKeysFrameItem("PAD4")
        end
    end
end

-- Сместить фокус на следующий или предыдущий пункт, минуя разделители.
local function MoveFocus(delta)
    if not dataProvider then
        return
    end

    local totalItems = dataProvider:GetSize()
    if totalItems <= 0 then
        return
    end

    local newIndex = focusedIndex
    for _ = 1, totalItems do
        newIndex = newIndex + delta
        if newIndex < 1 then
            newIndex = totalItems
        elseif newIndex > totalItems then
            newIndex = 1
        end

        local candidate = dataProvider.collection[newIndex]
        if candidate and candidate.type ~= "separator" then
            LoadNearItemListTooltipData(candidate)

            if candidate.type == "merchantItem" then
                LoadNearItemListStackSizeData(candidate)
            end

            UpdateFocus(candidate, true)
            UpdateMerchantActionKeys(candidate)
            ConsoleMenu:UpdateKeysFrame()
            return
        end
    end

    -- Если все элементы оказались разделителями, фокус не меняем.
end

-- Обновить подсказки кнопок торговца из текущего фокуса.
function ConsoleMenu:UpdateItemListFrameKeysFrame()
    if not dataProvider or not dataProvider.collection then
        UpdateMerchantActionKeys(nil)
        return
    end

    UpdateMerchantActionKeys(GetFocusedElement())
end

-- Купить товар, выкупить предмет или продать содержимое ячейки сумки.
local function PrimaryAction()
    local focusedElement = GetFocusedElement()
    if not focusedElement or not focusedSlot then
        return
    end

    if focusedElement.type == "merchantItem" then
        if focusedElement.isUnavailable then
            return
        end
        BuyMerchantItem(focusedSlot)
    elseif focusedElement.type == "buybackItem" then
        BuybackItem(focusedSlot)
    elseif focusedElement.type == "bagItem" and focusedElement.bag ~= nil then
        C_Container.UseContainerItem(focusedElement.bag, focusedSlot)
    end
end

-- Купить пачку товаров или продать весь хлам.
local function SecondaryAction()
    local tab = tabs[focusedTabIndex]
    if tab and tab.code == "sell" then
        if CanSellAllJunk() then
            C_MerchantFrame.SellAllJunkItems()
        end
        return
    end

    if not tab or tab.code ~= "trade" then
        return
    end

    local focusedElement = GetFocusedElement()
    if not focusedElement or not focusedSlot then
        return
    end

    if focusedElement.type ~= "merchantItem" or focusedElement.isUnavailable then
        return
    end

    local quantity = GetListItemStackSize(focusedElement)
    if quantity <= 1 then
        return
    end

    BuyMerchantItem(focusedSlot, quantity)
end

-- Отремонтировать всё снаряжение.
local function TertiaryAction()
    local tab = tabs[focusedTabIndex]
    if not tab or tab.code ~= "trade" then
        return
    end

    if NeedsEquipmentRepair() then
        RepairAllItems()
    end
end

-- Построить элемент списка товаров.
local function BuildMerchantItemElement(item, isUnavailable)
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

-- Построить элемент списка выкупа.
local function BuildBuybackItemElement(item)
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

-- Построить элемент списка продажи из сумки.
local function BuildBagItemElement(item)
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
    }
end

-- Диапазон сумок персонажа: рюкзак, обычные сумки и сумка реагентов.
local function GetCharacterBagIndexRange()
    local firstBag = (Enum and Enum.BagIndex and Enum.BagIndex.Backpack) or 0
    local numBagSlots = (Constants and Constants.InventoryConstants and Constants.InventoryConstants.NumBagSlots) or NUM_BAG_SLOTS or 4
    local numReagentBagSlots = (Constants and Constants.InventoryConstants and Constants.InventoryConstants.NumReagentBagSlots) or NUM_REAGENTBAG_SLOTS or 1
    return firstBag, firstBag + numBagSlots + numReagentBagSlots
end

-- Серый предмет считается хламом для продажи торговцу.
local function IsJunkQuality(quality)
    local poorQuality = (Enum and Enum.ItemQuality and Enum.ItemQuality.Poor) or 0
    return quality == poorQuality
end

-- Текст пустого списка и подпись под ним.
local function SetEmptyListContent(title, description)
    local emptyList = ConsoleMenuFrame and ConsoleMenuFrame.ItemListFrame and ConsoleMenuFrame.ItemListFrame.EmptyList
    if not emptyList then
        return
    end

    if emptyList.Text then
        emptyList.Text:SetText(title or "")
    end
    if emptyList.Description then
        emptyList.Description:SetText(description or "")
    end
end

-- Показать или скрыть пустой список.
local function SetEmptyListShown(isShown)
    local emptyList = ConsoleMenuFrame and ConsoleMenuFrame.ItemListFrame and ConsoleMenuFrame.ItemListFrame.EmptyList
    if not emptyList then
        return
    end

    if isShown then
        emptyList:Show()
    else
        emptyList:Hide()
    end
end

-- После заполнения списка подгрузить подсказки вокруг фокуса или первого пункта.
local function PreloadNearFocusedOrFirst()
    if not dataProvider or not dataProvider.collection then
        return
    end

    local target = nil
    if focusedSlot and focusedItemType then
        target = FindListItemElementBySlot(focusedSlot, focusedItemType)
    end
    if not target then
        for _, element in ipairs(dataProvider.collection) do
            if IsListItemType(element.type) then
                target = element
                break
            end
        end
    end

    if not target then
        return
    end

    LoadNearItemListTooltipData(target)
    if target.type == "merchantItem" then
        LoadNearItemListStackSizeData(target)
    end
end

-- Загрузить товары торговца.
local function LoadMerchantData()
    if not dataProvider then
        return
    end

    ClearItemListTooltipDataCache()
    ClearItemListStackSizeDataCache()
    dataProvider:Flush()

    local merchantName = UnitName("npc") or UnitName("NPC") or "Торговец"
    SetEmptyListContent(
        merchantName .. " не может предложить товары на продажу",
        "Вы можете заняться продажей или выкупом предметов."
    )

    local count = GetMerchantNumItems() or 0
    if count == 0 then
        SetEmptyListShown(true)
        ReanchorItemListBackground(count)
        return
    end

    SetEmptyListShown(false)
    ReanchorItemListBackground(count)

    local availableItems = {}
    local unavailableItems = {}

    for i = 1, count do
        local info = C_MerchantFrame.GetItemInfo(i)
        local itemID = GetMerchantItemID(i)
        local isHeirloom = itemID and C_Heirloom.IsItemHeirloom(itemID)
        local isKnownHeirloom = isHeirloom and C_Heirloom.PlayerHasHeirloom(itemID)
        local hasTransmog = itemID and C_TransmogCollection.PlayerHasTransmogByItemInfo(itemID)

        if info then
            info.itemID = itemID
            info.slot = i
            if not info.isPurchasable or (not info.isUsable and not isHeirloom) or info.numAvailable == 0 or isKnownHeirloom or hasTransmog then
                table.insert(unavailableItems, info)
            else
                table.insert(availableItems, info)
            end
        end
    end

    for _, item in ipairs(availableItems) do
        dataProvider:Insert(BuildMerchantItemElement(item, false))
    end

    if #unavailableItems > 0 then
        dataProvider:Insert({
            type = "separator",
            name = "Недоступные предметы",
        })

        for _, item in ipairs(unavailableItems) do
            dataProvider:Insert(BuildMerchantItemElement(item, true))
        end
    end

    PreloadNearFocusedOrFirst()
end

-- Загрузить предметы выкупа.
local function LoadBuybackData()
    if not dataProvider then
        return
    end

    ClearItemListTooltipDataCache()
    ClearItemListStackSizeDataCache()
    dataProvider:Flush()

    SetEmptyListContent(
        "Нет предметов для выкупа",
        "Продайте предмет торговцу, чтобы выкупить его позже."
    )

    local count = GetNumBuybackItems() or 0
    if count == 0 then
        SetEmptyListShown(true)
        ReanchorItemListBackground(count)
        return
    end

    SetEmptyListShown(false)
    ReanchorItemListBackground(count)

    for i = 1, count do
        local name, texture, price, quantity, numAvailable, isUsable = GetBuybackItemInfo(i)
        if name then
            local itemID = C_MerchantFrame.GetBuybackItemID and C_MerchantFrame.GetBuybackItemID(i) or nil
            dataProvider:Insert(BuildBuybackItemElement({
                slot = i,
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

    PreloadNearFocusedOrFirst()
end

-- Загрузить продаваемые предметы из сумок персонажа.
local function LoadSellData()
    if not dataProvider then
        return
    end

    ClearItemListTooltipDataCache()
    ClearItemListStackSizeDataCache()
    dataProvider:Flush()

    SetEmptyListContent(
        "Нет предметов для продажи",
        "В сумках нет вещей, которые этот торговец купит."
    )

    local junkItems = {}
    local classGroups = {}
    local classOrder = {}

    local firstBag, lastBag = GetCharacterBagIndexRange()
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
                    local totalPrice = 0
                    if sellPrice and sellPrice > 0 then
                        totalPrice = sellPrice * stackCount
                    end

                    local item = {
                        bag = bag,
                        slot = slot,
                        itemID = info.itemID,
                        name = info.itemName or itemName or "",
                        texture = info.iconFileID,
                        price = totalPrice,
                        stackCount = stackCount,
                        quality = info.quality,
                        classID = classID,
                    }

                    if IsJunkQuality(info.quality) then
                        table.insert(junkItems, item)
                    elseif classID then
                        if not classGroups[classID] then
                            classGroups[classID] = {}
                            table.insert(classOrder, classID)
                        end
                        table.insert(classGroups[classID], item)
                    end
                end
            end
        end
    end

    table.sort(classOrder)

    -- Добавить разделитель категории и предметы группы в список.
    local function InsertSellGroup(title, items)
        if not items or #items == 0 then
            return
        end

        dataProvider:Insert({
            type = "separator",
            name = title,
        })

        for _, item in ipairs(items) do
            dataProvider:Insert(BuildBagItemElement(item))
        end
    end

    InsertSellGroup("Хлам", junkItems)
    for _, classID in ipairs(classOrder) do
        local className = C_Item.GetItemClassInfo(classID)
        InsertSellGroup(className ~= "" and className or "Разное", classGroups[classID])
    end

    local count = #junkItems
    for _, classID in ipairs(classOrder) do
        count = count + #classGroups[classID]
    end

    if count == 0 then
        SetEmptyListShown(true)
        ReanchorItemListBackground(count)
        return
    end

    SetEmptyListShown(false)
    ReanchorItemListBackground(count)
    PreloadNearFocusedOrFirst()
end

-- Обновить одну строку блока валют.
local function UpdateCurrencyItemFrame(frame, item)
    if not frame then
        return
    end

    if not item then
        frame:Hide()
        return
    end
    
    frame:Show()

    if not frame.Icon then return end

    if item.texture then
        frame.Icon:Show()
        frame.Icon.MainTexture:SetTexture(item.texture)
        
    else
        frame.Icon:Hide()
    end

    if item.name and item.count then
        frame.Text:SetText(item.name .. " " .. item.separator .. item.count)
    elseif item.name then
        frame.Text:SetText(item.name)
    else
        frame.Text:SetText("")
    end

end

-- Обновить блок валют справа.
local function UpdateCurrenciesFrame()
    local itemListFrame = ConsoleMenuFrame and ConsoleMenuFrame.ItemListFrame
    if not itemListFrame or not itemListFrame.Currencies or not currenciesData then
        return
    end

    for i = 1, currenciesMaxItems do
        local currencyFrame = itemListFrame.Currencies["Item" .. i]
        local item = currenciesData[i]
        UpdateCurrencyItemFrame(currencyFrame, item)
    end
end

-- Считать золото и валюты текущего торговца.
local function LoadMerchantCurrenciesData()
    currenciesData = {}

    table.insert(currenciesData, {
        count = GetMoneyString(GetMoney(), true),
        name = "Золото",
        texture = "Interface\\Icons\\UI_PlunderCoins.tga",
        separator = ""
    })

    local merchantCurrencyIDs = nil
    if C_MerchantFrame.GetMerchantCurrencies then
        merchantCurrencyIDs = C_MerchantFrame.GetMerchantCurrencies()
    end
    if not merchantCurrencyIDs and GetMerchantCurrencies then
        merchantCurrencyIDs = { GetMerchantCurrencies() }
    end

    if merchantCurrencyIDs then
        for i = 1, #merchantCurrencyIDs do
            if #currenciesData >= currenciesMaxItems then
                break
            end

            local currencyID = merchantCurrencyIDs[i]
            if currencyID then
                local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
                if info then
                    table.insert(currenciesData, {
                        texture = info.iconFileID,
                        name = info.name,
                        count = info.quantity,
                        separator = "x",
                    })
                end
            end
        end
    end
end

-- Вкладки торговли, продажи и выкупа.
local function BuildTabs()
    tabs = {
        { title = "Торговля", code = "trade" },
        { title = "Продажа", code = "sell" },
        { title = "Выкуп", code = "buyback" },
    }
end

-- Загрузить содержимое выбранной вкладки.
local function LoadTabData(tab)
    if not tab then
        return
    end

    if tab.code == "trade" then
        LoadMerchantData()
    elseif tab.code == "sell" then
        LoadSellData()
    elseif tab.code == "buyback" then
        LoadBuybackData()
    end
end

-- Обновление фреймов вкладок в зависимости от фокуса
local function UpdateTabs()
    for i = 1, #tabs do
        local tab = _G["ItemListTab" .. i]
        if not tab then
            return
        end
        if i == focusedTabIndex then
            tab.circle:Hide()
            tab.text:Show()
            local textWidth = tab.text:GetStringWidth()
            tab:SetWidth(textWidth)
        else
            tab.circle:Show()
            tab.text:Hide()

            local diff = math.abs(focusedTabIndex - i)

            if diff == 1 then
                tab.circle:SetSize(sectionPadding, sectionPadding)
                tab:SetWidth(sectionPadding)
            else
                local newSize = sectionPadding * ((#tabs - diff) / #tabs + 0.35)
                tab.circle:SetSize(newSize, newSize)
                tab:SetWidth(newSize)
            end
        end
    end
end

local function RefreshMerchantTabsLayout()
    local frame = ConsoleMenuFrame and ConsoleMenuFrame.ItemListFrame
    if not frame or not frame.Tabs then
        return
    end

    local previousTab = nil
    for i = 1, #tabs do
        local tab = _G["ItemListTab" .. i]
        local tabData = tabs[i]
        if tab and tabData then
            tab.text:SetText(tabData.title)
            tab:Show()
            tab:ClearAllPoints()
            if i == 1 then
                tab:SetPoint("LEFT", ItemListTabs, "LEFT", sectionPadding * 1.5, 0)
            else
                tab:SetPoint("LEFT", previousTab, "RIGHT", sectionPadding, 0)
            end
            previousTab = tab
        end
    end

    for i = #tabs + 1, merchantTabSlotCount do
        local tab = _G["ItemListTab" .. i]
        if tab then
            tab:Hide()
        end
    end

    if focusedTabIndex > #tabs then
        focusedTabIndex = 1
    end

    UpdateTabs()
end

-- Поставить фокус на первый товар, предмет выкупа или предмет из сумки.
local function FocusFirstListElement()
    if not dataProvider or not dataProvider.collection then
        focusedIndex = 1
        focusedSlot = nil
        focusedBag = nil
        focusedItemType = nil
        focusedItemExtent = sectionHeight
        UpdateMerchantActionKeys(nil)
        ConsoleMenu:UpdateKeysFrame()
        return
    end

    local targetElement = nil
    for _, element in ipairs(dataProvider.collection) do
        if IsListItemType(element.type) then
            targetElement = element
            break
        end
    end

    if targetElement then
        LoadNearItemListTooltipData(targetElement)
        if targetElement.type == "merchantItem" then
            LoadNearItemListStackSizeData(targetElement)
        end
        UpdateFocus(targetElement, true)
        UpdateMerchantActionKeys(targetElement)
        ConsoleMenu:UpdateKeysFrame()
    else
        focusedIndex = 1
        focusedSlot = nil
        focusedBag = nil
        focusedItemType = nil
        focusedItemExtent = sectionHeight
        UpdateMerchantActionKeys(nil)
        ConsoleMenu:UpdateKeysFrame()
    end

    UpdateItemsScrollBarLayout()
end

-- Восстановить фокус по сохранённой ячейке или взять соседний пункт.
local function RestoreOrFocusFirstListElement()
    local restored = nil
    if focusedSlot and focusedItemType then
        restored = FindListItemElementBySlot(focusedSlot, focusedItemType, focusedBag)
    elseif lastFocusedSlot and lastFocusedType then
        restored = FindListItemElementBySlot(lastFocusedSlot, lastFocusedType, lastFocusedBag)
    end

    if not restored then
        restored = FindNearestListItemElement(lastFocusedIndex or focusedIndex)
    end

    if restored then
        LoadNearItemListTooltipData(restored)
        if restored.type == "merchantItem" then
            LoadNearItemListStackSizeData(restored)
        end
        UpdateFocus(restored, true)
        UpdateMerchantActionKeys(restored)
        ConsoleMenu:UpdateKeysFrame()
        UpdateItemsScrollBarLayout()
        return
    end

    FocusFirstListElement()
end

-- Выбрать вкладку по номеру.
local function SelectTab(index)
    if index < 1 or index > #tabs then
        return
    end

    focusedTabIndex = index
    LoadTabData(tabs[index])
    UpdateTabs()
    FocusFirstListElement()
end

-- Переключить вкладку влево или вправо.
local function SwitchTab(direction)
    if #tabs == 0 then
        return
    end

    local newTabIndex = focusedTabIndex + direction
    if newTabIndex < 1 then
        newTabIndex = #tabs
    elseif newTabIndex > #tabs then
        newTabIndex = 1
    end

    SelectTab(newTabIndex)
end

-- Одна отложенная пересборка списка по событиям торговца.
local function ScheduleMerchantRefresh(rebuildTabs)
    merchantRefreshRebuildTabs = merchantRefreshRebuildTabs or rebuildTabs
    if merchantRefreshQueued then
        return
    end

    merchantRefreshQueued = true
    C_Timer.After(0, function()
        merchantRefreshQueued = false
        local needTabs = merchantRefreshRebuildTabs
        merchantRefreshRebuildTabs = false

        local frame = ConsoleMenuFrame and ConsoleMenuFrame.ItemListFrame
        if not frame then
            return
        end

        if needTabs then
            BuildTabs()
            focusedTabIndex = 1
            RefreshMerchantTabsLayout()
        end

        local tab = tabs[focusedTabIndex]
        if tab then
            LoadTabData(tab)
        end

        LoadMerchantCurrenciesData()
        UpdateCurrenciesFrame()
        RestoreOrFocusFirstListElement()
        UpdateItemsScrollBarLayout()
    end)
end

-- Переназначение кнопок контроллера.
local function ApplyItemListOverrideBindings(frame)
    if not frame then
        return
    end

    if InCombatLockdown() then
        pendingOverrideBindings = true
        return
    end

    pendingOverrideBindings = false
    pendingClearOverrideBindings = false

    SetOverrideBindingClick(frame.FocusUpButton, true, "PADDUP", "ItemListFocusUpButton", "LeftButton")
    SetOverrideBindingClick(frame.FocusDownButton, true, "PADDDOWN", "ItemListFocusDownButton", "LeftButton")
    SetOverrideBindingClick(frame.TabLeftButton, true, "PADDLEFT", "ItemListTabLeftButton", "LeftButton")
    SetOverrideBindingClick(frame.TabRightButton, true, "PADDRIGHT", "ItemListTabRightButton", "LeftButton")
    SetOverrideBindingClick(frame.PrimaryButton, true, "PAD1", "ItemListPrimaryButton", "LeftButton")
    SetOverrideBindingClick(frame.SecondaryButton, true, "PAD4", "ItemListSecondaryButton", "LeftButton")
    SetOverrideBindingClick(frame.TertiaryButton, true, "PAD3", "ItemListTertiaryButton", "LeftButton")
    SetOverrideBindingClick(frame.CloseButton, true, "PAD2", "ItemListCloseButton", "LeftButton")
end

-- Снять переназначение кнопок контроллера.
local function ClearItemListOverrideBindings(frame)
    if not frame then
        return
    end

    if InCombatLockdown() then
        pendingClearOverrideBindings = true
        return
    end

    pendingClearOverrideBindings = false
    pendingOverrideBindings = false

    ClearOverrideBindings(frame)
    local buttons = {
        frame.FocusUpButton,
        frame.FocusDownButton,
        frame.TabLeftButton,
        frame.TabRightButton,
        frame.PrimaryButton,
        frame.SecondaryButton,
        frame.TertiaryButton,
        frame.CloseButton,
    }
    for _, button in ipairs(buttons) do
        if button then
            ClearOverrideBindings(button)
        end
    end
end

-- Подписка на золото, валюты и обновление сумок, пока окно открыто.
local function SetMerchantMoneyEventsRegistered(frame, isRegistered)
    if not frame then
        return
    end

    if isRegistered then
        if moneyEventsRegistered then
            return
        end
        frame:RegisterEvent("PLAYER_MONEY")
        frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
        frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
        frame:RegisterEvent("BAG_UPDATE_DELAYED")
        moneyEventsRegistered = true
    else
        if not moneyEventsRegistered then
            return
        end
        frame:UnregisterEvent("PLAYER_MONEY")
        frame:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
        frame:UnregisterEvent("UPDATE_INVENTORY_DURABILITY")
        frame:UnregisterEvent("BAG_UPDATE_DELAYED")
        moneyEventsRegistered = false
    end
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
local function BuildTooltipDescriptionText(tooltipData)
    local tooltipLines = tooltipData and tooltipData.lines
    if not tooltipLines then
        return nil
    end

    local sellPriceLineType = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.SellPrice
    local parts = {}
    local added = 0

    for tooltipLineIndex = 2, #tooltipLines do
        if added >= maxTooltipDescriptionLines then
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

-- Создать круглую текстуру значка валюты.
local function CreateCurrencyIconTexture(parent, drawLayer, subLevel)
    local texture = parent:CreateTexture(nil, drawLayer, nil, subLevel)
    local mask = parent:CreateMaskTexture()
    mask:SetAllPoints(texture)
    mask:SetTexture(
        "Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png",
        "CLAMPTOBLACK"
    )
    texture:AddMaskTexture(mask)
    return texture, mask
end

-- Обычное расположение значка и текста в строке списка.
local function ApplyDefaultItemLayout(frame)
    frame.icon:ClearAllPoints()
    frame.icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.text:ClearAllPoints()
    frame.text:SetPoint("LEFT", frame.icon, "RIGHT", sectionPadding * 2, -2)
    frame.text:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding * 4, -2)
end

-- Расположение текста разделителя без значка.
local function ApplySeparatorLayout(frame)
    frame.text:ClearAllPoints()
    frame.text:SetPoint("LEFT", frame, "LEFT", 0, -2)
    frame.text:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding * 4, -2)
end

-- Расположение выделенной строки с развёрнутым описанием.
local function ApplyExpandedItemLayout(frame)
    frame.icon:ClearAllPoints()
    frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -sectionPadding)
    frame.text:ClearAllPoints()
    frame.text:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", sectionPadding * 2, 0)
    frame.text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -sectionPadding * 4, -sectionPadding)
end

-- Высота блока цены с учётом значков валют.
local function UpdatePriceFrameHeight(frame)
    local textHeight = frame.text.price.text:GetStringHeight()
    if textHeight <= 0 then
        textHeight = itemFontSize
    end

    local iconHeight = 0
    if frame.text.price.icon:IsShown() then
        iconHeight = currencyIconSize
        if frame.text.price.icon.texture2:IsShown() then
            iconHeight = currencyIconDualHeight
        end
    end

    frame.text.price:SetHeight(math.max(textHeight, iconHeight))
end

-- Высота текста строки: название, одно описание и цена.
local function UpdateItemListTextHeight(frame)
    local titleHeight = frame.text.title:GetStringHeight()
    if titleHeight <= 0 then
        titleHeight = itemFontSize
    end

    local totalHeight = titleHeight
    local hasDescription = frame.text.description and frame.text.description:IsShown()
    local descriptionHeight = 0

    if hasDescription then
        descriptionHeight = frame.text.description:GetStringHeight()
        if descriptionHeight <= 0 then
            descriptionHeight = descriptionFontSize
        end
        totalHeight = totalHeight + sectionPadding + descriptionHeight
    end

    if frame.text.price and frame.text.price:IsShown() then
        local priceHeight = frame.text.price.text:GetStringHeight()
        if priceHeight <= 0 then
            priceHeight = itemFontSize
        end
        local priceIconHeight = currencyIconSize
        if frame.text.price.icon.texture2:IsShown() then
            priceIconHeight = currencyIconDualHeight
        end
        priceHeight = math.max(priceHeight, priceIconHeight)
        local priceTopGap = sectionPadding
        if descriptionHeight > descriptionFontSize * 1.5 then
            priceTopGap = sectionPadding * 2
        end
        totalHeight = totalHeight + priceTopGap + priceHeight
    end

    frame.text.height = totalHeight
    frame.text:SetHeight(totalHeight)
end

-- Скрыть описание и цену выделенной строки.
local function CollapseItemListElementText(frame)
    if frame.text.description then
        frame.text.description:SetText("")
        frame.text.description:Hide()
    end
    if frame.text.lines then
        for _, lineText in ipairs(frame.text.lines) do
            lineText:Hide()
            lineText:SetText("")
        end
    end
    frame.text.price.text:SetText("")
    frame.text.price:Hide()
    frame.text.price.icon.texture:SetTexture(nil)
    frame.text.price.icon.texture2:SetTexture(nil)
    frame.text.price.icon.texture2:Hide()
    frame.text.price.icon:SetSize(currencyIconSize, currencyIconSize)
    frame.text.price.icon:Hide()
    frame.text.price:SetHeight(0)
end

-- Показать или скрыть подробности выбранной строки.
local function SetItemListElementFocused(frame, isFocused)
    local data = frame.listData
    if not data then
        return false
    end

    if not isFocused or not IsListItemType(data.type) or not data.slot then
        local wasExpanded = frame:GetHeight() > sectionHeight
        if not wasExpanded and frame.text.description and not frame.text.description:IsShown() then
            frame.text.title:SetFont("Fonts\\FRIZQT___CYR.TTF", itemFontSize, "OUTLINE")
            frame.text.title:SetText(data.name or "")
            if data.type == "separator" then
                frame.text:SetAlpha(1)
            else
                frame.text:SetAlpha(unfocusedItemTextAlpha)
            end
            return false
        end

        frame:SetHeight(sectionHeight)
        frame.text.title:SetFont("Fonts\\FRIZQT___CYR.TTF", itemFontSize, "OUTLINE")
        frame.text.title:SetText(data.name or "")
        if data.type == "separator" then
            frame.text:SetAlpha(1)
            ApplySeparatorLayout(frame)
        else
            frame.text:SetAlpha(unfocusedItemTextAlpha)
            ApplyDefaultItemLayout(frame)
        end
        CollapseItemListElementText(frame)
        UpdateItemListTextHeight(frame)
        return wasExpanded
    end

    frame.text.title:SetFont("Fonts\\FRIZQT___CYR.TTF", focusedItemFontSize, "OUTLINE")
    if data.stackCount and data.stackCount > 1 then
        frame.text.title:SetText(string.format("%s x%d", data.name, data.stackCount))
    else
        frame.text.title:SetText(data.name or "")
    end
    frame.text:SetAlpha(1)

    local tooltipData = GetListItemTooltipData(data)
    local descriptionText = BuildTooltipDescriptionText(tooltipData)
    if descriptionText then
        local descriptionWidth = math.max(80, frameWidth - contentPadding - iconSize - sectionPadding * 6)
        frame.text.description:ClearAllPoints()
        frame.text.description:SetPoint("TOPLEFT", frame.text.title, "BOTTOMLEFT", 0, -sectionPadding)
        frame.text.description:SetPoint("TOPRIGHT", frame.text.title, "BOTTOMRIGHT", 0, -sectionPadding)
        frame.text.description:SetWidth(descriptionWidth)
        frame.text.description:SetText(descriptionText)
        frame.text.description:Show()
    else
        frame.text.description:SetText("")
        frame.text.description:Hide()
    end

    local priceText = nil
    local priceIconTextures = {}
    if not data.isUnavailable and IsListItemType(data.type) then
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

                    if costTexture and costTexture ~= 0 and #priceIconTextures < 2 then
                        table.insert(priceIconTextures, costTexture)
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
                priceText = table.concat(formattedCostParts, ", ")
            end
        elseif data.price and data.price > 0 then
            priceText = GetMoneyString(data.price, true)
        end
    end

    frame.text.price:ClearAllPoints()
    frame.text.price.icon:ClearAllPoints()
    frame.text.price.text:ClearAllPoints()

    if frame.text.description:IsShown() then
        local descriptionHeight = frame.text.description:GetStringHeight()
        local priceTopGap = sectionPadding
        if descriptionHeight > descriptionFontSize * 1.5 then
            priceTopGap = sectionPadding * 2
        end
        frame.text.price:SetPoint("TOPLEFT", frame.text.description, "BOTTOMLEFT", 0, -priceTopGap)
    else
        frame.text.price:SetPoint("TOPLEFT", frame.text.title, "BOTTOMLEFT", 0, -sectionPadding)
    end
    frame.text.price:SetPoint("TOPRIGHT", frame.text, "TOPRIGHT", 0, 0)

    if priceText then
        if #priceIconTextures > 0 then
            local priceIcon = frame.text.price.icon
            local iconOffset = currencyIconSize - currencyIconOverlap

            priceIcon.texture:ClearAllPoints()
            priceIcon.texture2:ClearAllPoints()

            if #priceIconTextures >= 2 then
                priceIcon:SetSize(currencyIconSize, currencyIconDualHeight)
                priceIcon.texture:SetPoint("TOPLEFT", priceIcon, "TOPLEFT", 0, 0)
                priceIcon.texture:SetPoint("BOTTOMRIGHT", priceIcon, "TOPLEFT", currencyIconSize, -currencyIconSize)
                priceIcon.texture:SetTexture(priceIconTextures[1])

                priceIcon.texture2:SetTexture(priceIconTextures[2])
                priceIcon.texture2:SetPoint("TOPLEFT", priceIcon, "TOPLEFT", 0, -iconOffset)
                priceIcon.texture2:SetPoint(
                    "BOTTOMRIGHT",
                    priceIcon,
                    "TOPLEFT",
                    currencyIconSize,
                    -(currencyIconSize + iconOffset)
                )
                priceIcon.texture2:Show()
            else
                priceIcon:SetSize(currencyIconSize, currencyIconSize)
                priceIcon.texture:SetAllPoints()
                priceIcon.texture:SetTexture(priceIconTextures[1])
                priceIcon.texture2:SetTexture(nil)
                priceIcon.texture2:Hide()
            end

            priceIcon:SetPoint("LEFT", frame.text.price, "LEFT", 0, 0)
            priceIcon:Show()
            frame.text.price.text:SetPoint("LEFT", priceIcon, "RIGHT", sectionPadding, 0)
            frame.text.price.text:SetPoint("RIGHT", frame.text.price, "RIGHT", 0, 0)
        else
            frame.text.price.icon.texture:SetTexture(nil)
            frame.text.price.icon.texture2:SetTexture(nil)
            frame.text.price.icon.texture2:Hide()
            frame.text.price.icon:SetSize(currencyIconSize, currencyIconSize)
            frame.text.price.icon:Hide()
            frame.text.price.text:SetPoint("TOPLEFT", frame.text.price, "TOPLEFT", 0, 0)
            frame.text.price.text:SetPoint("TOPRIGHT", frame.text.price, "TOPRIGHT", 0, 0)
        end
        frame.text.price.text:SetText(priceText)
        UpdatePriceFrameHeight(frame)
        frame.text.price:Show()
    else
        frame.text.price.icon.texture:SetTexture(nil)
        frame.text.price.icon.texture2:SetTexture(nil)
        frame.text.price.icon.texture2:Hide()
        frame.text.price.icon:SetSize(currencyIconSize, currencyIconSize)
        frame.text.price.icon:Hide()
        frame.text.price.text:SetText("")
        frame.text.price:Hide()
        frame.text.price:SetHeight(0)
    end

    UpdateItemListTextHeight(frame)

    local newExtent = math.max(sectionHeight, (frame.text.height or sectionHeight) + sectionPadding * 2)
    frame:SetHeight(newExtent)
    if newExtent > sectionHeight then
        ApplyExpandedItemLayout(frame)
    else
        ApplyDefaultItemLayout(frame)
    end
    local previousExtent = focusedItemExtent
    focusedItemExtent = newExtent
    return previousExtent ~= newExtent
end

-- Отрисовать строку товара, выкупа или предмета из сумки.
local function InitializeItemListElement(frame, data)
    if not frame then return end

    -- Иконка
    if not frame.icon then
        frame.icon = CreateFrame("Frame", nil, frame)
        frame.icon:SetSize(iconSize, iconSize)
        frame.icon:SetPoint("LEFT", 0, 0)
    end


    if not frame.icon.texture then
        frame.icon.texture = frame.icon:CreateTexture(nil, "ARTWORK")
        frame.icon.texture:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 2, -2)
        frame.icon.texture:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -2, 2)
    end

    if not frame.icon.mask then
        frame.icon.mask = frame.icon:CreateMaskTexture()
        frame.icon.mask:SetAllPoints(frame.icon)
        frame.icon.mask:SetTexture(
            "Interface\\AddOns\\ConsoleMenu\\Assets\\Mask.png",
            "CLAMPTOBLACK"
        )
        frame.icon.texture:AddMaskTexture(frame.icon.mask)
    end

    if not frame.icon.border then
        frame.icon.border = frame.icon:CreateTexture(nil, "OVERLAY")
        frame.icon.border:SetAtlas("plunderstorm-actionbar-slot-border")
        frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -11, 11)
        frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 11, -11)
    end

    if not frame.icon.overlay then
        frame.icon.overlay = frame.icon:CreateTexture(nil, "OVERLAY", nil, 1)
        frame.icon.overlay:SetAllPoints(frame.icon.texture)
    end

    -- Текст
    if not frame.text then
        frame.text = CreateFrame("Frame", nil, frame)
        frame.text:SetPoint("LEFT", frame.icon, "RIGHT", sectionPadding * 2, 0)
        frame.text:SetHeight(sectionHeight)

        frame.text.title = frame.text:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.text.title:SetPoint("TOPLEFT", frame.text, "TOPLEFT", 0, 0)
        frame.text.title:SetPoint("TOPRIGHT", frame.text, "TOPRIGHT", 0, 0)
        frame.text.title:SetJustifyH("LEFT")
        frame.text.title:SetFont("Fonts\\FRIZQT___CYR.TTF", itemFontSize, "OUTLINE")

        frame.text.price = CreateFrame("Frame", nil, frame.text)
        frame.text.price:Hide()

        frame.text.price.text = frame.text.price:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.text.price.text:SetJustifyH("LEFT")
        frame.text.price.text:SetFont("Fonts\\FRIZQT___CYR.TTF", itemFontSize, "OUTLINE")
        frame.text.price.text:SetTextColor(1, 0.976, 0.855, 1)

        frame.text.price.icon = CreateFrame("Frame", nil, frame.text.price)
        frame.text.price.icon:SetSize(currencyIconSize, currencyIconSize)

        frame.text.price.icon.texture, frame.text.price.icon.mask = CreateCurrencyIconTexture(
            frame.text.price.icon,
            "ARTWORK",
            0
        )
        frame.text.price.icon.texture:SetAllPoints()

        frame.text.price.icon.texture2, frame.text.price.icon.mask2 = CreateCurrencyIconTexture(
            frame.text.price.icon,
            "ARTWORK",
            1
        )
        frame.text.price.icon.texture2:Hide()
        frame.text.price.icon:Hide()

        frame.text.description = frame.text:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.text.description:SetJustifyH("LEFT")
        frame.text.description:SetJustifyV("TOP")
        frame.text.description:SetNonSpaceWrap(true)
        frame.text.description:SetWordWrap(true)
        frame.text.description:SetFont("Fonts\\FRIZQT___CYR.TTF", descriptionFontSize, "")
        frame.text.description:Hide()
    end

    if not frame.text.description then
        frame.text.description = frame.text:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.text.description:SetJustifyH("LEFT")
        frame.text.description:SetJustifyV("TOP")
        frame.text.description:SetNonSpaceWrap(true)
        frame.text.description:SetWordWrap(true)
        frame.text.description:SetFont("Fonts\\FRIZQT___CYR.TTF", descriptionFontSize, "")
        frame.text.description:Hide()
    end

    -- Жесткий reset визуального состояния обязателен:
    -- ScrollBox переиспользует один и тот же frame для разных данных.
    frame.text.title:SetText("")
    frame.text:Show()
    frame.text:SetAlpha(1)
    frame.text.title:SetAlpha(1)
    frame.text.title:SetTextColor(1, 0.976, 0.855, 1)
    frame.icon:Show()
    frame.icon.texture:SetTexture(nil)
    frame.icon.texture:SetDesaturated(false)
    frame.icon.texture:Hide()
    frame.icon.border:Hide()
    frame.icon.overlay:Hide()
    CollapseItemListElementText(frame)

    if not data then
        frame.listData = nil
        frame:SetHeight(sectionHeight)
        frame.text:Hide()
        return
    end

    frame.listData = data
    frame.text.title:SetText(data.name or "")

    if data.type == "merchantItem" or data.type == "buybackItem" or data.type == "bagItem" then
        ApplyDefaultItemLayout(frame)
        frame.text.title:SetTextColor(1, 0.976, 0.855, 1)

        frame.icon.texture:SetTexture(data.texture)
        frame.icon.texture:SetDesaturated(data.isUnavailable or false)
        frame.icon.texture:Show()
        frame.icon.border:Show()

        if data.itemID and C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(data.itemID) then
            frame.icon.overlay:SetAtlas("AzeriteIconFrame")
            frame.icon.overlay:Show()
        elseif data.itemID and C_Item.IsCorruptedItem(data.itemID) then
            frame.icon.overlay:SetAtlas("Nzoth-inventory-icon")
            frame.icon.overlay:Show()
        elseif data.itemID and C_Item.IsCosmeticItem(data.itemID) then
            frame.icon.overlay:SetAtlas("CosmeticIconFrame")
            frame.icon.overlay:Show()
        elseif data.itemID and C_Soulbinds.IsItemConduitByItemInfo(data.itemID) then
            frame.icon.overlay:SetAtlas("ConduitIconFrame")
            frame.icon.overlay:Show()
        elseif data.itemID and (C_Item.IsCurioItem(data.itemID) or C_Item.IsRelicItem(data.itemID)) then
            frame.icon.overlay:SetAtlas("delves-curios-icon-border")
            frame.icon.overlay:Show()
        else
            frame.icon.overlay:Hide()
        end
    elseif data.type == "separator" then
        ApplySeparatorLayout(frame)
        frame.text.title:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
        frame.icon:Hide()
    else
        -- Неизвестный тип: оставляем безопасный базовый текстовый стиль.
        ApplyDefaultItemLayout(frame)
        frame.text.title:SetTextColor(1, 0.976, 0.855, 1)
    end

    frame.SetFocused = SetItemListElementFocused
    frame:SetFocused(IsFocusedListElement(data))

end

-- Подписки при показе окна торговца.
local function OnItemListFrameShow(self)
    SetMerchantMoneyEventsRegistered(self, true)
    RestoreOrFocusFirstListElement()
    ApplyItemListOverrideBindings(self)
end

-- Сброс фокуса и привязок при скрытии окна торговца.
local function OnItemListFrameHide(self)
    lastFocusedSlot = focusedSlot
    lastFocusedBag = focusedBag
    lastFocusedType = focusedItemType
    lastFocusedIndex = focusedIndex
    focusedSlot = nil
    focusedBag = nil
    focusedItemType = nil
    focusedItemExtent = sectionHeight
    SetMerchantMoneyEventsRegistered(self, false)
    ClearItemListOverrideBindings(self)
end

-- Обработка событий окна торговца.
local function OnItemListFrameEvent(self, event, ...)
    if event == "MERCHANT_CLOSED" then
        ResetMerchantSelection()
        if dataProvider then
            dataProvider:Flush()
        end
        currenciesData = {}
        tabs = {}
        focusedTabIndex = 1
        SetMerchantMoneyEventsRegistered(self, false)
        return
    end

    if event == "TOOLTIP_DATA_UPDATE" then
        local dataInstanceID = ...
        OnTooltipDataUpdate(dataInstanceID)
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if pendingClearOverrideBindings and not self:IsShown() then
            ClearItemListOverrideBindings(self)
        elseif pendingOverrideBindings and self:IsShown() then
            ApplyItemListOverrideBindings(self)
        end
        return
    end

    if event == "PLAYER_MONEY" or event == "CURRENCY_DISPLAY_UPDATE" then
        LoadMerchantCurrenciesData()
        UpdateCurrenciesFrame()
        UpdateMerchantActionKeys(GetFocusedElement())
        ConsoleMenu:UpdateKeysFrame()
        return
    end

    if event == "UPDATE_INVENTORY_DURABILITY" then
        UpdateMerchantActionKeys(GetFocusedElement())
        ConsoleMenu:UpdateKeysFrame()
        return
    end

    if event == "MERCHANT_SHOW" then
        ResetMerchantSelection()
        ScheduleMerchantRefresh(true)
        return
    end

    if event == "BAG_UPDATE_DELAYED" then
        local tab = tabs[focusedTabIndex]
        if tab and tab.code == "sell" then
            ScheduleMerchantRefresh(false)
        end
        return
    end

    if event == "MERCHANT_UPDATE" then
        ScheduleMerchantRefresh(false)
    end
end

-- Инициализация фрейма торговца
function ConsoleMenu:SetItemListFrame()

    if ConsoleMenuFrame.ItemListFrame and ConsoleMenuFrame.ItemListFrame.IsMerchantFrameInitialized then
        return
    end

    if not ConsoleMenuFrame.ItemListFrame then
        local frame = CreateFrame("Frame", "ItemListFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.ItemListFrame = frame
    end

    local frame = ConsoleMenuFrame.ItemListFrame
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

    frame:SetPoint("TOPLEFT", ConsoleMenuFrame, "TOPLEFT", frameLeftOffset, -48 * 4)
    frame:SetWidth(frameWidth)
    frame:SetPoint("BOTTOMLEFT", ConsoleMenuFrame, "BOTTOMLEFT", frameLeftOffset, 48 * 4 + 2)
    frame:Hide()

    if not frame.Background then
        frame.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.Background:SetParent(frame)
        frame.Background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorundDark.png")
        frame.Background:SetDrawLayer("BACKGROUND", 0)
        frame.Background:Show()
        frame.Background:SetAlpha(1)

    end

    if not frame.AdditionalShadow then
        frame.AdditionalShadow = frame:CreateTexture(nil, "BACKGROUND")
        frame.AdditionalShadow:SetParent(frame)
        frame.AdditionalShadow:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorundDark.png")
        frame.AdditionalShadow:SetDrawLayer("BACKGROUND", 0)
        frame.AdditionalShadow:Show()
        frame.AdditionalShadow:SetAlpha(1)
    end

    ReanchorItemListBackground(0)

    if not frame.EmptyList then
        local emptyList = CreateFrame("Frame", "ItemListFrameEmptyList", frame)
        frame.EmptyList = emptyList
        emptyList:SetPoint("TOPLEFT", frame, "TOPLEFT", contentPadding, 0)
        emptyList:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 128, 0)
        emptyList:SetHeight(160)

        local text = emptyList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyList.Text = text
        text:SetPoint("TOPLEFT", emptyList, "TOPLEFT", 0, 0)
        text:SetWidth(frameWidth)
        text:SetJustifyH("LEFT")
        text:SetNonSpaceWrap(true)
        text:SetFont("Fonts\\morpheus_cyr.ttf", emptyListFontSize, "OUTLINE")
        text:SetTextColor(1, 0.976, 0.855, 1)
        text:SetText("")

        local description = emptyList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyList.Description = description
        description:SetPoint("TOPLEFT", emptyList.Text, "BOTTOMLEFT", 0, -24)
        description:SetWidth(frameWidth)
        description:SetJustifyH("LEFT")
        description:SetNonSpaceWrap(true)
        description:SetFont("Fonts\\FRIZQT___CYR.TTF", emptyListDescriptionFontSize, "OUTLINE")
        description:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
        description:SetText("Вы можете заняться продажей или выкупом предметов.")
    end

    if not frame.Items then
        local items = CreateFrame("Frame", "ItemListFrameItems", frame)
        frame.Items = items
        items:SetAllPoints(frame)

        local scrollBox = CreateFrame("Frame", "ItemListFrameScrollBox", items, "WowScrollBoxList")
        items.ScrollBox = scrollBox
        scrollBox:SetPoint("TOPLEFT", items, "TOPLEFT", contentPadding, 0)
        scrollBox:SetPoint("BOTTOMRIGHT", items, "BOTTOMRIGHT", 0, sectionHeight)

        local scrollBar = CreateFrame("EventFrame", "ItemListFrameScrollBar", items, "MinimalScrollBar")
        items.ScrollBar = scrollBar

        scrollBar:SetAlpha(0.4)
        scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPLEFT", -contentPadding, -24)
        scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMLEFT", 0, 24)
        scrollBar.Forward:Hide()
        scrollBar.Back:Hide()

        local scrollView = CreateScrollBoxListLinearView()
        items.ScrollView = scrollView
        dataProvider = CreateDataProvider()

        if scrollView.SetElementExtentCalculator then
            scrollView:SetElementExtentCalculator(function(index, elementData)
                local data = elementData
                if type(data) ~= "table" and type(index) == "table" then
                    data = index
                end

                return GetItemListElementExtent(data)
            end)
        else
            scrollView:SetElementExtent(sectionHeight)
        end
        scrollView:SetElementInitializer("Button", InitializeItemListElement)
    
        ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
        scrollBox:SetDataProvider(dataProvider)
        
    end

    if not frame.Currencies then
        local currencies = CreateFrame("Frame", "ItemListCurrencies", frame)
        frame.Currencies = currencies
        currencies:SetSize(currenciesWidth, currenciesHeight)
        currencies:SetPoint("TOPRIGHT", ConsoleMenuFrame, "TOPRIGHT", -64, -48 * 4)

        if not currencies.Background then
            currencies.Background = currencies:CreateTexture(nil, "BACKGROUND")
            currencies.Background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorundDark.png")
            currencies.Background:SetDrawLayer("BACKGROUND", 0)
            currencies.Background:SetPoint("LEFT", currencies, "LEFT", -itemListBackgroundHOffset, 0)
            currencies.Background:SetPoint("RIGHT", currencies, "RIGHT", itemListBackgroundHOffset * 2, 0)
            
            currencies.Background:SetPoint("TOP", currencies, "TOP", 0, itemListBackgroundVOffset * 0.8)
            currencies.Background:SetPoint("BOTTOM", currencies, "BOTTOM", 0, -itemListBackgroundVOffset * 0.8)
            currencies.Background:SetAlpha(0.75)
            currencies.Background:Show()
        end

        for i = 1, currenciesMaxItems do
            local item = CreateFrame("Frame", "CurrenciesItem" .. i, currencies)
            currencies["Item" .. i] = item
    
            item:SetWidth(currenciesWidth)
            item:SetHeight(currenciesSectionHeight)
    
            item:Hide()
    
            if i == 1 then
                item:SetPoint("TOPLEFT", currencies, "TOPLEFT", 0, 0)
            else
                item:SetPoint("TOPLEFT", currencies["Item" .. (i-1)], "BOTTOMLEFT", 0, -currenciesIconInnerPadding * 1.5)
            end
    
            ConsoleMenu:InitFadeAnimations(item, animationDuration)
    
            -- Иконка
            if not item.Icon then
                item.Icon = CreateFrame("Frame", nil, item)
                item.Icon:SetSize(currenciesIconSize, currenciesIconSize)
                item.Icon:SetPoint("RIGHT", item, "RIGHT", 0, 0)
    
                -- Текстура иконки
                if not item.Icon.MainTexture then
                    item.Icon.MainTexture = item.Icon:CreateTexture(nil, "ARTWORK")
                    item.Icon.MainTexture:SetAllPoints()

                    item.Icon.Mask = item.Icon:CreateMaskTexture()
                    item.Icon.Mask:SetAllPoints(item.Icon.MainTexture)
                    item.Icon.Mask:SetTexture(
                        "Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png",
                        "CLAMPTOBLACK"
                    )
                    item.Icon.MainTexture:AddMaskTexture(item.Icon.Mask)
                end
            end
    
            -- Текст
            if not item.Text then
                item.Text = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                item.Text:SetPoint("RIGHT", item.Icon, "LEFT", -currenciesIconInnerPadding * 2, 0)
                item.Text:SetJustifyH("LEFT")
                item.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", currenciesFontSize, "")
                item.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
            end
    
        end
    end

    if not frame.Tabs then
        frame.Tabs = CreateFrame("Frame", "ItemListTabs", frame)
        frame.Tabs:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 26, 0)
        frame.Tabs:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        frame.Tabs:SetHeight(sectionHeight)

        local previousTab = nil
        for i = 1, merchantTabSlotCount do
            local tab = CreateFrame("Button", "ItemListTab" .. i, ItemListTabs)
            if i == 1 then
                tab:SetPoint("LEFT", ItemListTabs, "LEFT", sectionPadding * 1.5, 0)
            else
                tab:SetPoint("LEFT", previousTab, "RIGHT", sectionPadding, 0)
            end

            local tabFont = "Fonts\\FRIZQT___CYR.TTF"
            if not tab.text then
                tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                tab.text:SetFont(tabFont, tabFontSize, "")
                tab.text:SetTextColor(1.0, 0.960784, 0.772549, 0.4)
                tab.text:SetPoint("CENTER")
            end

            if not tab.circle then
                tab.circle = CreateFrame("Frame", nil, tab)
                tab.circle:SetSize(sectionPadding, sectionPadding)
                tab.circle:SetPoint("CENTER", tab, "CENTER", 0, 0)

                tab.circle.texture = tab.circle:CreateTexture(nil, "ARTWORK")
                tab.circle.texture:SetAllPoints(tab.circle)
                tab.circle.texture:SetColorTexture(1.0, 0.960784, 0.772549, 0.4)
                tab.circle.texture:SetTexCoord(0, 1, 0, 1)

                tab.circle.mask = tab.circle:CreateMaskTexture()
                tab.circle.mask:SetAllPoints(tab.circle)
                tab.circle.mask:SetTexture(
                    "Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png",
                    "CLAMPTOBLACK"
                )

                tab.circle.texture:AddMaskTexture(tab.circle.mask)
            end

            tab.circle:Hide()
            tab:SetHeight(sectionHeight)
            tab:Hide()

            tab:SetScript("OnClick", function()
                SelectTab(i)
            end)

            previousTab = tab
        end
    end

    if not frame.FocusUpButton then
        local focusUpButton = CreateFrame("Button", "ItemListFocusUpButton", frame, "SecureActionButtonTemplate")
        frame.FocusUpButton = focusUpButton
        focusUpButton:SetAttribute("useOnKeyDown", false)
        focusUpButton:RegisterForClicks("LeftButtonUp")
        focusUpButton:SetSize(1, 1)
        focusUpButton:SetPoint("TOPLEFT", frame, "TOPLEFT")
        focusUpButton:SetScript("OnClick", function()
            MoveFocus(-1)
        end)
    end

    if not frame.FocusDownButton then
        local focusDownButton = CreateFrame("Button", "ItemListFocusDownButton", frame, "SecureActionButtonTemplate")
        frame.FocusDownButton = focusDownButton
        focusDownButton:SetAttribute("useOnKeyDown", false)
        focusDownButton:RegisterForClicks("LeftButtonUp")
        focusDownButton:SetSize(1, 1)
        focusDownButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 20)
        focusDownButton:SetScript("OnClick", function()
            MoveFocus(1)
        end)
    end

    if not frame.TabLeftButton then
        local tabLeftButton = CreateFrame("Button", "ItemListTabLeftButton", frame, "SecureActionButtonTemplate")
        frame.TabLeftButton = tabLeftButton
        tabLeftButton:SetAttribute("useOnKeyDown", false)
        tabLeftButton:RegisterForClicks("LeftButtonUp")
        tabLeftButton:SetSize(1, 1)
        tabLeftButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 100)
        tabLeftButton:SetScript("OnClick", function()
            SwitchTab(-1)
        end)
    end

    if not frame.TabRightButton then
        local tabRightButton = CreateFrame("Button", "ItemListTabRightButton", frame, "SecureActionButtonTemplate")
        frame.TabRightButton = tabRightButton
        tabRightButton:SetAttribute("useOnKeyDown", false)
        tabRightButton:RegisterForClicks("LeftButtonUp")
        tabRightButton:SetSize(1, 1)
        tabRightButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 120)
        tabRightButton:SetScript("OnClick", function()
            SwitchTab(1)
        end)
    end

    if not frame.PrimaryButton then
        local primaryButton = CreateFrame("Button", "ItemListPrimaryButton", frame, "SecureActionButtonTemplate")
        frame.PrimaryButton = primaryButton
        primaryButton:SetAttribute("useOnKeyDown", false)
        primaryButton:RegisterForClicks("LeftButtonUp")
        primaryButton:SetSize(1, 1)
        primaryButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 40)
        primaryButton:SetScript("OnClick", function()
            PrimaryAction()
        end)
    end

    if not frame.SecondaryButton then
        local secondaryButton = CreateFrame("Button", "ItemListSecondaryButton", frame, "SecureActionButtonTemplate")
        frame.SecondaryButton = secondaryButton
        secondaryButton:SetAttribute("useOnKeyDown", false)
        secondaryButton:RegisterForClicks("LeftButtonUp")
        secondaryButton:SetSize(1, 1)
        secondaryButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 80)
        secondaryButton:SetScript("OnClick", function()
            SecondaryAction()
        end)
    end

    if not frame.TertiaryButton then
        local tertiaryButton = CreateFrame("Button", "ItemListTertiaryButton", frame, "SecureActionButtonTemplate")
        frame.TertiaryButton = tertiaryButton
        tertiaryButton:SetAttribute("useOnKeyDown", false)
        tertiaryButton:RegisterForClicks("LeftButtonUp")
        tertiaryButton:SetSize(1, 1)
        tertiaryButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 140)
        tertiaryButton:SetScript("OnClick", function()
            TertiaryAction()
        end)
    end

    if not frame.CloseButton then
        local closeButton = CreateFrame("Button", "ItemListCloseButton", frame, "SecureActionButtonTemplate")
        frame.CloseButton = closeButton
        closeButton:SetAttribute("useOnKeyDown", false)
        closeButton:RegisterForClicks("LeftButtonUp")
        closeButton:SetSize(1, 1)
        closeButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 60)
        closeButton:SetScript("OnClick", function()
            CloseMerchant()
        end)
    end

    if not frame.FocusBindingHooksSet then
        frame.FocusBindingHooksSet = true

        frame:HookScript("OnShow", OnItemListFrameShow)
        frame:HookScript("OnHide", OnItemListFrameHide)
    end

    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("MERCHANT_UPDATE")
    frame:RegisterEvent("MERCHANT_CLOSED")
    frame:RegisterEvent("TOOLTIP_DATA_UPDATE")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    frame:SetScript("OnEvent", OnItemListFrameEvent)

    frame.IsMerchantFrameInitialized = true
end

-- Показать фрейм торговца
function ConsoleMenu:ShowItemListFrame()
    local frame = ConsoleMenuFrame and ConsoleMenuFrame.ItemListFrame
    if not frame or not dataProvider then
        return
    end

    local children = { MerchantFrame:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
    end

    local merchantRegions = { MerchantFrame:GetRegions() }
    for _, region in ipairs(merchantRegions) do
        if region and region.Hide then
            region:Hide()
        end
    end

    UpdateItemsScrollBarLayout()
    UpdateCurrenciesFrame()
    ConsoleMenu:AnimatedShow(frame)

end

-- Скрыть фрейм торговца
function ConsoleMenu:HideItemListFrame()
    local frame = ConsoleMenuFrame and ConsoleMenuFrame.ItemListFrame
    if not frame or not dataProvider then
        return
    end

    ConsoleMenu:AnimatedHide(frame)
end