local ConsoleMenu = _G.ConsoleMenu

local dataProvider

local frameWidth = 480
local contentPadding = 52
local backdropTemplateOffset = 20

local viewedItemCount = 10

local sectionHeight = 80
local sectionPadding = 10
local unfocusedItemTextAlpha = 0.6
local itemsSectionHeight = sectionHeight * viewedItemCount

local iconSize = sectionHeight - sectionPadding * 2

local titleFontSize = 24
local titleSectionHeight = titleFontSize

local emptyListFontSize = 32
local emptyListDescriptionFontSize = 20

local itemFontSize = 18
local focusedItemFontSize = itemFontSize + 2
local descriptionFontSize = 14
local tabFontSize = 22

local focusedTabIndex = 1
local tabs = {}
local merchantTabSlotCount = 3

local currencyIconSize = 20
local currencyIconOverlap = currencyIconSize / 4
local currencyIconDualHeight = currencyIconSize * 2 - currencyIconOverlap

local focusedIndex = 1
local focusedSlot = nil
local focusedItemExtent = sectionHeigh

local itemListTooltipDataCache = {}
local itemListStackSizeDataCache = {}

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

-- Функция для получения высоты элемента списка предметов
local function GetItemListElementExtent(elementData)
    if elementData
        and elementData.type == "merchantItem"
        and focusedSlot
        and elementData.slot == focusedSlot
    then
        return math.max(sectionHeight, focusedItemExtent)
    end

    return sectionHeight
end

-- Функция для обновления фокуса на элементе списка предметов
local function UpdateFocus(element, changeFocus)
    if not element then return end

    local frame = ConsoleMenuFrame and ConsoleMenuFrame.ItemListFrame
    if not frame or not frame.Items or not frame.Items.ScrollBox then
        return
    end

    local scrollBox = frame.Items.ScrollBox
    local layoutChanged = false

    focusedIndex = scrollBox:FindElementDataIndex(element)
    if not focusedIndex then return end

    local nextSlot = (element.type == "merchantItem") and element.slot or nil
    local slotChanged = nextSlot ~= focusedSlot
    if slotChanged then
        focusedItemExtent = sectionHeight
    end
    focusedSlot = nextSlot

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

    if focusedFrame and focusedFrame.SetFocused and changeFocus then
        layoutChanged = focusedFrame:SetFocused(true) or layoutChanged
    end

    if layoutChanged or slotChanged then
        UpdateItemsScrollBarLayout()
    end

    if changeFocus then
        scrollBox:ScrollToElementDataIndex(focusedIndex)
    end
end

local function GetFocusedElement()
    if not dataProvider or not dataProvider.collection then
        return nil
    end
    return dataProvider.collection[focusedIndex]
end

local function GetListItemStackSize(element)
    if not element or not element.slot then
        return 1
    end

    local slot = element.slot
    local cachedStackSize = itemListStackSizeDataCache[slot]
    if cachedStackSize then
        return cachedStackSize
    end

    local quantity = 1
    local itemID
    
    if element.type == "merchantItem" then
        itemID = element.itemID or GetMerchantItemID(slot)
        if itemID then
            local stackSize = C_Item.GetItemMaxStackSizeByID(itemID)
            if stackSize and stackSize > 0 then
                quantity = stackSize
            end
        end
    end

    itemListStackSizeDataCache[slot] = quantity
    return quantity
end

local function GetListItemTooltipData(element)
    if not element or not element.slot then
        return nil
    end

    local slot = element.slot
    local cachedTooltipData = itemListTooltipDataCache[slot]
    if cachedTooltipData then
        return cachedTooltipData
    end

    if element.type == "merchantItem" then
        local tooltipData = C_TooltipInfo.GetMerchantItem(slot)
        itemListTooltipDataCache[slot] = tooltipData
        return tooltipData
    end

    return nil
end

local function FindListItemElementBySlot(slot)
    if not dataProvider or not slot then
        return nil
    end

    for _, element in ipairs(dataProvider.collection) do
        if element.type ~= "separator" and element.slot == slot then
            return element
        end
    end

    -- Заглушка
    return {
        type = "merchantItem",
        slot = slot,
    }
end

local function LoadNearItemListTooltipData(element)
    if not element or not element.slot then
        return
    end

    GetListItemTooltipData(element)

    local slot = element.slot
    local nextSlot = slot + 1
    local previousSlot = slot - 1

    if nextSlot <= GetMerchantNumItems() then
        GetListItemTooltipData(FindListItemElementBySlot(nextSlot))
    end

    if previousSlot >= 1 then
        GetListItemTooltipData(FindListItemElementBySlot(previousSlot))
    end
end

local function LoadNearItemListStackSizeData(element)
    if not element or not element.slot then
        return
    end

    GetListItemStackSize(element)

    local slot = element.slot
    local nextSlot = slot + 1
    local previousSlot = slot - 1

    if nextSlot <= GetMerchantNumItems() then
        GetListItemStackSize(FindListItemElementBySlot(nextSlot))
    end

    if previousSlot >= 1 then
        GetListItemStackSize(FindListItemElementBySlot(previousSlot))
    end
end

local function ClearItemListTooltipDataCache()
    for slot in pairs(itemListTooltipDataCache) do
        itemListTooltipDataCache[slot] = nil
    end
end

local function ClearItemListStackSizeDataCache()
    for slot in pairs(itemListStackSizeDataCache) do
        itemListStackSizeDataCache[slot] = nil
    end
end

local function UpdateMerchantActionKeys(element)

    if element and element.type == "merchantItem" and not element.isUnavailable then
        ConsoleMenu:AddKeysFrameItem("PAD1", "Купить предмет")
        ConsoleMenu:AddKeysFrameItem("PAD3", "Отремонтировать снаряжение")
        if GetListItemStackSize(element) > 1 then
            ConsoleMenu:AddKeysFrameItem("PAD4", "Купить пачку предметов")
        else
            ConsoleMenu:DeleteKeysFrameItem("PAD4")
        end
    else
        ConsoleMenu:DeleteKeysFrameItem("PAD1")
        ConsoleMenu:DeleteKeysFrameItem("PAD4")
    end

end

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

function ConsoleMenu:UpdateItemListFrameKeysFrame()
    local candidate = dataProvider.collection[focusedIndex]
    UpdateMerchantActionKeys(candidate)
end

--  Купить предмет
local function PrimaryAction()
    if not focusedSlot then
        return
    end

    local focusedElement = GetFocusedElement()

    if not focusedElement then
        return
    end

    if focusedElement.type == "merchantItem" then
        if focusedElement.isUnavailable then
            return
        end

        BuyMerchantItem(focusedSlot)
    end
end

-- Купить пачку предметов
local function SecondaryAction()
    local tab = tabs[focusedTabIndex]
    if not tab then
        return
    end

    if tab.code == "trade" then
        if not focusedSlot then
            return
        end
    
        local focusedElement = GetFocusedElement()
        if not focusedElement then
            return
        end
    
        if focusedElement.type == "merchantItem" then
    
            if focusedElement.isUnavailable then
                return
            end
    
            local quantity = GetListItemStackSize(focusedElement)
    
            if quantity == 1 then
                return
            end
    
            BuyMerchantItem(focusedSlot, quantity)
        end
    end
end

local function TertiaryAction()
    local tab = tabs[focusedTabIndex]

    if tab.code == "trade" then
        if CanMerchantRepair() then
            RepairAllItems()
        end
    end

end

-- Построить элемент списка предметов
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

-- Загрузить данные торговца
local function LoadMerchantData()
    -- Очистка данных

    -- Очистить кэш tooltip данных
    ClearItemListTooltipDataCache()

    -- Очистить кэш размера пачек предметов
    ClearItemListStackSizeDataCache()

    -- Очистить скролл бокса
    dataProvider:Flush()
    
    -- Загрузка данных
    -- Загрузить tooltip данные для первых предметов / предметов в окрестности предмета в фокусе
    if focusedSlot then
        LoadNearItemListTooltipData(FindListItemElementBySlot(focusedSlot))
        LoadNearItemListStackSizeData(FindListItemElementBySlot(focusedSlot))
    else
        LoadNearItemListTooltipData(FindListItemElementBySlot(1))
        LoadNearItemListStackSizeData(FindListItemElementBySlot(1))
    end

    -- Загрузка данных о продавце
    local text = UnitName("NPC") .. " не может предложить товары на продажу"
    ConsoleMenuFrame.ItemListFrame.EmptyList.Text:SetText(text)

    -- Загрузка данных предметов

    local availableItems = {}
    local unavailableItems = {}

    local count = GetMerchantNumItems()

    if count == 0 then
        ConsoleMenuFrame.ItemListFrame.EmptyList:Show()
        ReanchorItemListBackground(count)
        return
    else
        ConsoleMenuFrame.ItemListFrame.EmptyList:Hide()
    end

    ReanchorItemListBackground(count)

    for i = 1, count do
        local info = C_MerchantFrame.GetItemInfo(i)
        local itemID = GetMerchantItemID(i)
        local isHeirloom = itemID and C_Heirloom.IsItemHeirloom(itemID)
        local isKnownHeirloom = isHeirloom and C_Heirloom.PlayerHasHeirloom(itemID)
        local hasTransmog = C_TransmogCollection.PlayerHasTransmogByItemInfo(itemID)

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

    -- Добавление доступных предметов
    for _, item in ipairs(availableItems) do
        dataProvider:Insert(BuildMerchantItemElement(item, false))
    end

    -- Добавление секции недоступных предметов
    if #unavailableItems > 0 then
        dataProvider:Insert({
            type = "separator",
            name = "Недоступные предметы",
        })

        for _, item in ipairs(unavailableItems) do
            dataProvider:Insert(BuildMerchantItemElement(item, true))
        end
    end
end

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

local function LoadMerchantCurrenciesData()
    currenciesData = {}

    table.insert(currenciesData, {
        count = GetMoneyString(GetMoney(), true),
        name = "Золото",
        texture = "Interface\\Icons\\UI_PlunderCoins.tga",
        separator = ""
    })

    local merchantCurrencyIDs = C_MerchantFrame.GetMerchantCurrencies()
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

local function BuildTabs()
    tabs = {
        { title = "Торговля", code = "trade" },
        { title = "Выкуп", code = "buyback" },
        { title = "Продажа", code = "sell" },
    }
end

local function LoadTabData(tab)
    if not tab then
        return
    end

    if tab.code == "trade" then
        LoadMerchantData()
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

local function FocusFirstListElement()
    if not dataProvider or not dataProvider.collection then
        focusedIndex = 1
        focusedSlot = nil
        return
    end

    local targetElement = nil
    for _, element in ipairs(dataProvider.collection) do
        if element.type ~= "separator" then
            targetElement = element
            break
        end
    end

    if targetElement then
        UpdateFocus(targetElement, true)
        UpdateMerchantActionKeys(targetElement)
        ConsoleMenu:UpdateKeysFrame()
    else
        focusedIndex = 1
        focusedSlot = nil
        focusedItemExtent = sectionHeight
        UpdateMerchantActionKeys(nil)
        ConsoleMenu:UpdateKeysFrame()
    end

    UpdateItemsScrollBarLayout()
end

local function SelectTab(index)
    if index < 1 or index > #tabs then
        return
    end

    focusedTabIndex = index
    LoadTabData(tabs[index])
    UpdateTabs()
    FocusFirstListElement()
end

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

-- Инициализация фрейма торговца
function ConsoleMenu:SetItemListFrame()

    if not ConsoleMenuFrame.ItemListFrame then
        local frame = CreateFrame("Frame", "ItemListFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.ItemListFrame = frame
    end

    local frame = ConsoleMenuFrame.ItemListFrame
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

    frame:SetPoint("TOPLEFT", ConsoleMenuFrame, "TOPLEFT", 48, -48 * 4)
    frame:SetWidth(frameWidth)
    frame:SetPoint("BOTTOMLEFT", ConsoleMenuFrame, "BOTTOMLEFT", 48, 48 * 4 + 2)
    --frame:SetSize(frameWidth, itemsSectionHeight + contentPadding * 2 + titleSectionHeight + 32)
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
        emptyList:SetPoint("TOPLEFT", frame, "TOPLEFT", 52, 0)
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

    -- if not frame.Title then
    --     local title = CreateFrame("Frame", "ItemListFrameTitle", frame)
    --     frame.Title = title
    --     title:SetPoint("TOPLEFT", frame, "TOPLEFT", contentPadding, -contentPadding)
    --     title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -contentPadding, -contentPadding)
    --     title:SetHeight(titleSectionHeight)

    --     if not frame.Title.Text then
    --         local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --         frame.Title.Text = text
    --         text:SetPoint("TOPLEFT", frame.Title, "TOPLEFT", 0, 0)
    --         text:SetPoint("TOPRIGHT", frame.Title, "TOPRIGHT", 0, 0)
    --         text:SetJustifyH("LEFT")
    --         text:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "")
    --         text:SetTextColor(1.0, 0.82, 0, 1)
    --         text:SetText("Продавец")
    --     end
    -- end

    if not frame.Items then
        local items = CreateFrame("Frame", "ItemListFrameItems", frame)
        frame.Items = items
        items:SetAllPoints(frame)
        --items:SetHeight(itemsSectionHeight)

        local scrollBox = CreateFrame("Frame", "ItemListFrameScrollBox", items, "WowScrollBoxList")
        items.ScrollBox = scrollBox
        scrollBox:SetPoint("TOPLEFT", items, "TOPLEFT", 52, 0)
        scrollBox:SetPoint("BOTTOMRIGHT", items, "BOTTOMRIGHT", 0, sectionHeight)

        local scrollBar = CreateFrame("EventFrame", "ItemListFrameScrollBar", items, "MinimalScrollBar")
        items.ScrollBar = scrollBar

        scrollBar:SetAlpha(0.4)
        scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPLEFT", -52, -24)
        scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMLEFT", 0, 24)
        scrollBar.Forward:Hide()
        scrollBar.Back:Hide()

        local scrollView = CreateScrollBoxListLinearView()
        items.ScrollView = scrollView
        dataProvider = CreateDataProvider()

        -- Инициализатор для элемента списка
        local function Initializer(frame, data)
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
            end

            if not frame.text.lines then
                frame.text.lines = {}
            end

            local function UpdateTextHeight()
                local titleHeight = frame.text.title:GetStringHeight()
                if titleHeight <= 0 then
                    titleHeight = itemFontSize
                end

                local totalHeight = titleHeight

                local visibleLineHeights = {}
                for _, lineText in ipairs(frame.text.lines) do
                    if lineText:IsShown() then
                        local lineHeight = lineText:GetStringHeight()
                        if lineHeight <= 0 then
                            lineHeight = descriptionFontSize
                        end
                        table.insert(visibleLineHeights, lineHeight)
                    end
                end

                if #visibleLineHeights > 0 then
                    -- Первая строка lines привязана к title с отступом -sectionPadding.
                    totalHeight = totalHeight + sectionPadding
                    for i, lineHeight in ipairs(visibleLineHeights) do
                        totalHeight = totalHeight + lineHeight
                        if i < #visibleLineHeights then
                            totalHeight = totalHeight
                        end
                    end
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
                    local descriptionLineCount = #visibleLineHeights
                    local priceTopGap = sectionPadding
                    if descriptionLineCount > 1 then
                        priceTopGap = sectionPadding * 2
                    end
                    totalHeight = totalHeight + priceTopGap + priceHeight
                end

                frame.text.height = totalHeight
                frame.text:SetHeight(totalHeight)
            end

            local function UpdatePriceFrameHeight()
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
            frame.text.price.text:SetText("")
            frame.text.price:Hide()
            frame.text.price.icon.texture:SetTexture(nil)
            frame.text.price.icon.texture2:SetTexture(nil)
            frame.text.price.icon.texture2:Hide()
            frame.text.price.icon:SetSize(currencyIconSize, currencyIconSize)
            frame.text.price.icon:Hide()
            frame.text.price:SetHeight(0)
            for _, lineText in ipairs(frame.text.lines) do
                lineText:Hide()
                lineText:SetText("")
            end
            UpdateTextHeight()

            if not data then
                frame:SetHeight(sectionHeight)
                frame.text:Hide()
                return
            end

            frame.text.title:SetText(data.name or "")

            if data.type == "merchantItem" then
                frame.text:ClearAllPoints()
                frame.text:SetPoint("LEFT", frame.icon, "RIGHT", sectionPadding * 2, -2)
                frame.text:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding * 4, -2)
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
                frame.text:ClearAllPoints()
                frame.text:SetPoint("LEFT", frame, "LEFT", 0, -2)
                frame.text:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding * 4, -2)
                frame.text.title:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
                frame.icon:Hide()
            else
                -- Неизвестный тип: оставляем безопасный базовый текстовый стиль.
                frame.text:ClearAllPoints()
                frame.text:SetPoint("LEFT", frame.icon, "RIGHT", sectionPadding * 2, -2)
                frame.text:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding * 4, -2)
                frame.text.title:SetTextColor(1, 0.976, 0.855, 1)
            end

            function frame:SetFocused(isFocused)

                local function SetDefaultTitleText()
                    frame.text.title:SetText(data.name or "")
                end

                local function SetFocusedTitleText()
                    if data.stackCount and data.stackCount > 1 then
                        frame.text.title:SetText(string.format("%s x%d", data.name, data.stackCount))
                    else
                        frame.text.title:SetText(data.name or "")
                    end
                end

                local function ApplyDefaultItemLayout()
                    frame.icon:ClearAllPoints()
                    frame.icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
                    frame.text:ClearAllPoints()
                    frame.text:SetPoint("LEFT", frame.icon, "RIGHT", sectionPadding * 2, -2)
                    frame.text:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding * 4, -2)
                end

                local function ApplySeparatorLayout()
                    frame.text:ClearAllPoints()
                    frame.text:SetPoint("LEFT", frame, "LEFT", 0, -2)
                    frame.text:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding * 4, -2)
                end

                local function ApplyExpandedItemLayout()
                    frame.icon:ClearAllPoints()
                    frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -sectionPadding)
                    frame.text:ClearAllPoints()
                    frame.text:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", sectionPadding * 2, 0)
                    frame.text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -sectionPadding * 4, -sectionPadding)
                end

                if not isFocused or data.type ~= "merchantItem" or not data.slot then
                    local wasExpanded = frame:GetHeight() > sectionHeight
                    frame:SetHeight(sectionHeight)
                    frame.text.title:SetFont("Fonts\\FRIZQT___CYR.TTF", itemFontSize, "OUTLINE")
                    SetDefaultTitleText()
                    if data.type == "separator" then
                        frame.text:SetAlpha(1)
                        ApplySeparatorLayout()
                    else
                        frame.text:SetAlpha(unfocusedItemTextAlpha)
                        ApplyDefaultItemLayout()
                    end
                    for _, lineText in ipairs(frame.text.lines) do
                        lineText:Hide()
                        lineText:SetText("")
                    end
                    frame.text.price.text:SetText("")
                    frame.text.price:Hide()
                    frame.text.price.icon.texture:SetTexture(nil)
                    frame.text.price.icon.texture2:SetTexture(nil)
                    frame.text.price.icon.texture2:Hide()
                    frame.text.price.icon:SetSize(currencyIconSize, currencyIconSize)
                    frame.text.price.icon:Hide()
                    frame.text.price:SetHeight(0)
                    UpdateTextHeight()
                    return wasExpanded
                end
                
                frame.text.title:SetFont("Fonts\\FRIZQT___CYR.TTF", focusedItemFontSize, "OUTLINE")

                local tooltipData = GetListItemTooltipData(data)

                frame.text:SetAlpha(1)
                SetFocusedTitleText()
                local tooltipLines = (tooltipData and tooltipData.lines) or {}
                local lineIndex = 1
                for tooltipLineIndex = 2, #tooltipLines do
                    local tooltipLine = tooltipLines[tooltipLineIndex]
                    local leftText = tooltipLine and tooltipLine.leftText
                    local containsAngleBrackets = leftText and leftText:find("<", 1, true) and leftText:find(">", 1, true)
                    if leftText and leftText ~= "" and not containsAngleBrackets then
                        local lineText = frame.text.lines[lineIndex]
                        if not lineText then
                            lineText = frame.text:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                            frame.text.lines[lineIndex] = lineText
                            lineText:SetJustifyH("LEFT")
                            lineText:SetFont("Fonts\\FRIZQT___CYR.TTF", descriptionFontSize, "")
                        end

                        lineText:ClearAllPoints()
                        if lineIndex == 1 then
                            lineText:SetPoint("TOPLEFT", frame.text.title, "BOTTOMLEFT", 0, -sectionPadding)
                            lineText:SetPoint("TOPRIGHT", frame.text.title, "BOTTOMRIGHT", 0, -sectionPadding)
                        else
                            lineText:SetPoint("TOPLEFT", frame.text.lines[lineIndex - 1], "BOTTOMLEFT", 0, -1)
                            lineText:SetPoint("TOPRIGHT", frame.text.lines[lineIndex - 1], "BOTTOMRIGHT", 0, -1)
                        end

                        local rightText = tooltipLine.rightText
                        local displayText = leftText
                        if rightText and rightText ~= "" then
                            local formattedRightText = rightText
                            local rightColor = tooltipLine.rightColor
                            if rightColor then
                                formattedRightText = CreateColor(
                                    rightColor.r or 0.9,
                                    rightColor.g or 0.9,
                                    rightColor.b or 0.9,
                                    rightColor.a or 0.95
                                ):WrapTextInColorCode(rightText)
                            end
                            displayText = leftText .. ", " .. formattedRightText
                        end

                        lineText:SetText(displayText)
                        local leftColor = tooltipLine.leftColor
                        if leftColor then
                            lineText:SetTextColor(
                                leftColor.r or 0.9,
                                leftColor.g or 0.9,
                                leftColor.b or 0.9,
                                leftColor.a or 0.95
                            )
                        else
                            lineText:SetTextColor(0.9, 0.9, 0.9, 0.95)
                        end
                        lineText:Show()
                        lineIndex = lineIndex + 1
                    end
                end

                for i = lineIndex, #frame.text.lines do
                    frame.text.lines[i]:Hide()
                    frame.text.lines[i]:SetText("")
                end

                local priceText = nil
                local priceIconTextures = {}
                if not data.isUnavailable and data.type == "merchantItem" then
                    local costCount = data.slot and (GetMerchantItemCostInfo(data.slot) or 0) or 0
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

                local descriptionLineCount = lineIndex - 1
                if descriptionLineCount > 1 then
                    frame.text.price:SetPoint("TOPLEFT", frame.text.lines[lineIndex - 1], "BOTTOMLEFT", 0, -sectionPadding * 2)
                elseif descriptionLineCount == 1 then
                    frame.text.price:SetPoint("TOPLEFT", frame.text.lines[lineIndex - 1], "BOTTOMLEFT", 0, -sectionPadding)
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
                    UpdatePriceFrameHeight()
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

                UpdateTextHeight()

                local newExtent = math.max(sectionHeight, (frame.text.height or sectionHeight) + sectionPadding * 2)
                frame:SetHeight(newExtent)
                if newExtent > sectionHeight then
                    ApplyExpandedItemLayout()
                else
                    ApplyDefaultItemLayout()
                end
                local previousExtent = focusedItemExtent
                focusedItemExtent = newExtent
                return previousExtent ~= newExtent
            end

            local isCurrentFocused = data.type == "merchantItem"
                and focusedSlot ~= nil
                and data.slot == focusedSlot
            frame:SetFocused(isCurrentFocused)

        end

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
        scrollView:SetElementInitializer("Button", Initializer, "SecureActionButtonTemplate")
    
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
        frame.Tabs:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 40, 0)
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

        frame:HookScript("OnShow", function(self)

            local targetElement = nil
            if lastFocusedSlot then
                for _, element in ipairs(dataProvider.collection) do
                    if element.type == "merchantItem" and element.slot == lastFocusedSlot then
                        targetElement = element
                        break
                    end
                end
            end

            if not targetElement then
                for _, element in ipairs(dataProvider.collection) do
                    if element.type == "merchantItem" then
                        targetElement = element
                        break
                    end
                end
            end

            if targetElement then
                UpdateFocus(targetElement, true)
            else
                focusedIndex = 1
                focusedSlot = nil
            end
            
            SetOverrideBindingClick(self.FocusUpButton, true, "PADDUP", "ItemListFocusUpButton", "LeftButton")
            SetOverrideBindingClick(self.FocusDownButton, true, "PADDDOWN", "ItemListFocusDownButton", "LeftButton")
            SetOverrideBindingClick(self.TabLeftButton, true, "PADDLEFT", "ItemListTabLeftButton", "LeftButton")
            SetOverrideBindingClick(self.TabRightButton, true, "PADDRIGHT", "ItemListTabRightButton", "LeftButton")
            SetOverrideBindingClick(self.PrimaryButton, true, "PAD1", "ItemListPrimaryButton", "LeftButton")
            SetOverrideBindingClick(self.SecondaryButton, true, "PAD4", "ItemListSecondaryButton", "LeftButton")
            SetOverrideBindingClick(self.TertiaryButton, true, "PAD3", "ItemListTertiaryButton", "LeftButton")
            SetOverrideBindingClick(self.CloseButton, true, "PAD2", "ItemListCloseButton", "LeftButton")
        end)

        frame:HookScript("OnHide", function(self)
            if InCombatLockdown() then return end

            focusedSlot = nil
            focusedItemExtent = sectionHeight

            ClearOverrideBindings(self)
            if self.FocusUpButton then
                ClearOverrideBindings(self.FocusUpButton)
            end
            if self.FocusDownButton then
                ClearOverrideBindings(self.FocusDownButton)
            end
            if self.TabLeftButton then
                ClearOverrideBindings(self.TabLeftButton)
            end
            if self.TabRightButton then
                ClearOverrideBindings(self.TabRightButton)
            end
            if self.PrimaryButton then
                ClearOverrideBindings(self.PrimaryButton)
            end
            if self.SecondaryButton then
                ClearOverrideBindings(self.SecondaryButton)
            end
            if self.TertiaryButton then
                ClearOverrideBindings(self.TertiaryButton)
            end
            if self.CloseButton then
                ClearOverrideBindings(self.CloseButton)
            end
        end)
    end

    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("MERCHANT_UPDATE")
    frame:RegisterEvent("MERCHANT_CLOSED")

    frame:SetScript("OnEvent", function(self, event, ...)

        if event == "MERCHANT_CLOSED" then
            ClearItemListTooltipDataCache()
            ClearItemListStackSizeDataCache()
            focusedItemExtent = sectionHeight
            dataProvider:Flush()
            currenciesData = {}
            tabs = {}
            focusedTabIndex = 1
            return
        end

        C_Timer.After(0, function()
            if event == "MERCHANT_SHOW" then
                BuildTabs()
                focusedTabIndex = 1
                RefreshMerchantTabsLayout()
            end

            local tab = tabs[focusedTabIndex]
            if tab then
                LoadTabData(tab)
            end

            LoadMerchantCurrenciesData()

            if focusedSlot then
                for _, element in ipairs(dataProvider.collection) do
                    if element.type == "merchantItem" and element.slot == focusedSlot then
                        UpdateFocus(element, true)
                        break
                    end
                end
            end

            UpdateCurrenciesFrame()
            UpdateItemsScrollBarLayout()
        end)
    end)
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