local ConsoleMenu = _G.ConsoleMenu

local dataProvider

local frameWidth = 480
local contentPadding = 52
local backdropTemplateOffset = 20

local titleSectionHeight = 32
local titleFontSize = 24

local viewedItemCount = 10

local sectionHeight = 76
local sectionPadding = 10
local unfocusedItemTextAlpha = 0.7
local itemsSectionHeight = sectionHeight * viewedItemCount

local iconSize = sectionHeight - sectionPadding * 2
local itemFontSize = 18
local descriptionFontSize = 14
local currencyIconSize = 18
local focusedTitleFontSize = itemFontSize + 2

local focusedIndex = 1
local focusedMerchantSlot = nil
local focusedItemExtent = sectionHeight

local merchantItemTooltipDataCache = {}

local animationDuration = 0.1

local merchantBackgroundVOffset = 600
local merchantBackgroundHOffset = 960

local function ReanchorMerchantBackground()
    local merchantFrame = ConsoleMenuFrame and ConsoleMenuFrame.MerchantFrame
    if not merchantFrame or not merchantFrame.background then
        return
    end

    local background = merchantFrame.background
    local anchorFrame = merchantFrame.Items or merchantFrame

    background:ClearAllPoints()
    background:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", -merchantBackgroundHOffset, merchantBackgroundVOffset)
    background:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", merchantBackgroundHOffset / 2, merchantBackgroundVOffset)
    background:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMLEFT", -merchantBackgroundHOffset, -merchantBackgroundVOffset)
    background:SetPoint("BOTTOMRIGHT", anchorFrame, "BOTTOMRIGHT", merchantBackgroundHOffset / 2, -merchantBackgroundVOffset)
end

local function RefreshMerchantScrollLayout()
    local merchantFrame = ConsoleMenuFrame and ConsoleMenuFrame.MerchantFrame
    local scrollBox = merchantFrame and merchantFrame.Items and merchantFrame.Items.ScrollBox
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

local function GetMerchantElementExtent(elementData)
    if elementData
        and elementData.type == "item"
        and focusedMerchantSlot
        and elementData.merchantSlot == focusedMerchantSlot
    then
        return math.max(sectionHeight, focusedItemExtent)
    end

    return sectionHeight
end

local function UpdateFocus(element, changeFocus)
    if not element then return end

    local frame = ConsoleMenuFrame and ConsoleMenuFrame.MerchantFrame
    if not frame or not frame.Items or not frame.Items.ScrollBox then
        return
    end

    local scrollBox = frame.Items.ScrollBox
    local frames = scrollBox:GetFrames()
    local layoutChanged = false

    for _, listItemFrame in ipairs(frames) do
        if listItemFrame.SetFocused then
            layoutChanged = listItemFrame:SetFocused(false) or layoutChanged
        end
    end

    focusedIndex = scrollBox:FindElementDataIndex(element)
    if not focusedIndex then return end

    local nextMerchantSlot = (element.type == "item") and element.merchantSlot or nil
    if nextMerchantSlot ~= focusedMerchantSlot then
        focusedItemExtent = sectionHeight
    end
    focusedMerchantSlot = nextMerchantSlot

    local focusedFrame = scrollBox:FindFrameByPredicate(function(listItemFrame, elementData)
        return elementData == element
    end)

    if focusedFrame and focusedFrame.SetFocused and changeFocus then
        layoutChanged = focusedFrame:SetFocused(true) or layoutChanged
    end

    if layoutChanged then
        RefreshMerchantScrollLayout()
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

local function GetMerchantItemStackSize(merchantSlot)
    local quantity = 1
    local itemID = merchantSlot and GetMerchantItemID(merchantSlot)
    if itemID then
        local stackSize = C_Item.GetItemMaxStackSizeByID(itemID)
        if stackSize and stackSize > 0 then
            quantity = stackSize
        end
    end
    return quantity
end

local function GetMerchantItemTooltipData(merchantSlot)
    if not merchantSlot then
        return nil
    end

    local cachedTooltipData = merchantItemTooltipDataCache[merchantSlot]
    if cachedTooltipData then
        return cachedTooltipData
    end

    local tooltipData = C_TooltipInfo.GetMerchantItem(merchantSlot)
    merchantItemTooltipDataCache[merchantSlot] = tooltipData
    return tooltipData
end

local function LoadNearItemsTooltipData(merchantSlot)
    if not merchantSlot then
        return
    end

    local nextSlot = merchantSlot + 1
    local previousSlot = merchantSlot - 1

    if nextSlot <= GetMerchantNumItems() and not merchantItemTooltipDataCache[nextSlot] then
        local nextTooltipData = GetMerchantItemTooltipData(nextSlot)
        if nextTooltipData then
            merchantItemTooltipDataCache[nextSlot] = nextTooltipData
        end
    end

    if previousSlot >= 1 and not merchantItemTooltipDataCache[previousSlot] then
        local previousTooltipData = GetMerchantItemTooltipData(previousSlot)
        if previousTooltipData then
            merchantItemTooltipDataCache[previousSlot] = previousTooltipData
        end
    end
end

local function ClearMerchantItemTooltipDataCache()
    for slot in pairs(merchantItemTooltipDataCache) do
        merchantItemTooltipDataCache[slot] = nil
    end
end

local function UpdateMerchantActionKeys(element)
    if element and not element.isUnavailable then
        ConsoleMenu:AddKeysFrameItem("PAD1", "Купить предмет")
        if GetMerchantItemStackSize(element.merchantSlot) > 1 then
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
            LoadNearItemsTooltipData(candidate.merchantSlot)
            UpdateFocus(candidate, true)
            UpdateMerchantActionKeys(candidate)
            ConsoleMenu:UpdateKeysFrame()
            return
        end
    end

    -- Если все элементы оказались разделителями, фокус не меняем.
end

function ConsoleMenu:UpdateMerchantFrameKeysFrame()
    local candidate = dataProvider.collection[focusedIndex]
    UpdateMerchantActionKeys(candidate)
end

--  Купить предмет
local function BuyFocusedItem()
    if not focusedMerchantSlot then
        return
    end

    local focusedElement = GetFocusedElement()
    if not focusedElement or focusedElement.isUnavailable then
        return
    end

    BuyMerchantItem(focusedMerchantSlot)
end

-- Купить пачку предметов
local function BuyFocusedItemStack()
    if not focusedMerchantSlot then
        return
    end

    local focusedElement = GetFocusedElement()
    if not focusedElement or focusedElement.isUnavailable then
        return
    end

    local quantity = GetMerchantItemStackSize(focusedMerchantSlot)

    if quantity == 1 then
        return
    end

    BuyMerchantItem(focusedMerchantSlot, quantity)
end

-- Загрузить данные торговца
local function BuildMerchantItemElement(item, isUnavailable)
    return {
        type = "item",
        isUnavailable = isUnavailable,
        merchantSlot = item.merchantSlot,
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

local function LoadMerchantData()
    -- Очистка данных
    -- Очистить кэш tooltip данных
    ClearMerchantItemTooltipDataCache()

    -- Очистить скролл бокса
    dataProvider:Flush()
    
    -- Загрузка данных
    -- Загрузить tooltip данные для первых двух предметов
    merchantItemTooltipDataCache[1] = C_TooltipInfo.GetMerchantItem(1)
    merchantItemTooltipDataCache[2] = C_TooltipInfo.GetMerchantItem(2)
    if focusedMerchantSlot then
        merchantItemTooltipDataCache[focusedMerchantSlot] = C_TooltipInfo.GetMerchantItem(focusedMerchantSlot)
    end


    -- Загрузка данных предметов

    local availableItems = {}
    local unavailableItems = {}

    local count = GetMerchantNumItems()
    for i = 1, count do
        local info = C_MerchantFrame.GetItemInfo(i)
        local itemID = GetMerchantItemID(i)
        local isHeirloom = itemID and C_Heirloom.IsItemHeirloom(itemID)
        local isKnownHeirloom = isHeirloom and C_Heirloom.PlayerHasHeirloom(itemID)
        local hasTransmog = C_TransmogCollection.PlayerHasTransmogByItemInfo(itemID)

        if info then
            info.itemID = itemID
            info.merchantSlot = i
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

-- Инициализация фрейма торговца
function ConsoleMenu:SetMerchantFrame()

    if not ConsoleMenuFrame.MerchantFrame then
        local frame = CreateFrame("Frame", "MerchantFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.MerchantFrame = frame
    end

    local frame = ConsoleMenuFrame.MerchantFrame
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

    frame:SetPoint("TOPLEFT", ConsoleMenuFrame, "TOPLEFT", 48, -48 * 4)
    frame:SetWidth(frameWidth)
    frame:SetPoint("BOTTOMLEFT", ConsoleMenuFrame, "BOTTOMLEFT", 48, 48 * 4)
    --frame:SetSize(frameWidth, itemsSectionHeight + contentPadding * 2 + titleSectionHeight + 32)
    frame:Hide()

    if not frame.background then
        frame.background = frame:CreateTexture(nil, "BACKGROUND")
        frame.background:SetParent(frame)
        frame.background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorundDark.png")
        frame.background:SetDrawLayer("BACKGROUND", 0)
        frame.background:Show()
        ReanchorMerchantBackground()
    end

    -- if not frame.Title then
    --     local title = CreateFrame("Frame", "MerchantFrameTitle", frame)
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
        local items = CreateFrame("Frame", "MerchantFrameItems", frame)
        frame.Items = items
        items:SetAllPoints(frame)
        --items:SetHeight(itemsSectionHeight)

        local scrollBox = CreateFrame("Frame", "MerchantFrameScrollBox", items, "WowScrollBoxList")
        items.ScrollBox = scrollBox
        scrollBox:SetPoint("TOPLEFT", items, "TOPLEFT", 48, 0)
        scrollBox:SetPoint("BOTTOMRIGHT", items, "BOTTOMRIGHT", 0, 0)

        local scrollBar = CreateFrame("EventFrame", "MerchantFrameScrollBar", items, "MinimalScrollBar")
        items.ScrollBar = scrollBar

        scrollBar:SetAlpha(0.7)
        scrollBar:SetPoint("TOPLEFT", items, "TOPLEFT", 0, -24)
        scrollBar:SetPoint("BOTTOMLEFT", items, "BOTTOMLEFT", 0, 24)
        scrollBar.Forward:Hide()
        scrollBar.Back:Hide()

        local scrollView = CreateScrollBoxListLinearView()
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
                frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -10, 10)
                frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 10, -10)
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
                frame.text.price.icon.texture = frame.text.price.icon:CreateTexture(nil, "ARTWORK")
                frame.text.price.icon.texture:SetAllPoints()
                frame.text.price.icon.mask = frame.text.price.icon:CreateMaskTexture()
                frame.text.price.icon.mask:SetAllPoints(frame.text.price.icon.texture)
                frame.text.price.icon.mask:SetTexture(
                    "Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png",
                    "CLAMPTOBLACK"
                )
                frame.text.price.icon.texture:AddMaskTexture(frame.text.price.icon.mask)
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
                    priceHeight = math.max(priceHeight, currencyIconSize)
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

            if data.type == "item" then
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

                if not isFocused or data.type ~= "item" or not data.merchantSlot then
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
                    frame.text.price.icon:Hide()
                    frame.text.price:SetHeight(0)
                    UpdateTextHeight()
                    return data.type == "item"
                        and focusedMerchantSlot
                        and data.merchantSlot == focusedMerchantSlot
                        and focusedItemExtent > sectionHeight
                end

                frame.text.title:SetFont("Fonts\\FRIZQT___CYR.TTF", focusedTitleFontSize, "OUTLINE")

                local tooltipData = GetMerchantItemTooltipData(data.merchantSlot)

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
                local priceIconTexture = nil
                if not data.isUnavailable then
                    local costCount = data.merchantSlot and (GetMerchantItemCostInfo(data.merchantSlot) or 0) or 0
                    if costCount > 0 and data.merchantSlot then
                        local costParts = {}

                        for costIndex = 1, costCount do
                            local costTexture, costValue, costLink, currencyName = GetMerchantItemCostItem(data.merchantSlot, costIndex)
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

                                if not priceIconTexture and costTexture and costTexture ~= 0 then
                                    priceIconTexture = costTexture
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
                    if priceIconTexture and priceIconTexture ~= 0 then
                        frame.text.price.icon.texture:SetTexture(priceIconTexture)
                        frame.text.price.icon:SetPoint("LEFT", frame.text.price, "LEFT", 0, 0)
                        frame.text.price.icon:Show()
                        frame.text.price.text:SetPoint("LEFT", frame.text.price.icon, "RIGHT", sectionPadding, 0)
                        frame.text.price.text:SetPoint("RIGHT", frame.text.price, "RIGHT", 0, 0)
                    else
                        frame.text.price.icon.texture:SetTexture(nil)
                        frame.text.price.icon:Hide()
                        frame.text.price.text:SetPoint("TOPLEFT", frame.text.price, "TOPLEFT", 0, 0)
                        frame.text.price.text:SetPoint("TOPRIGHT", frame.text.price, "TOPRIGHT", 0, 0)
                    end
                    frame.text.price.text:SetText(priceText)
                    UpdatePriceFrameHeight()
                    frame.text.price:Show()
                else
                    frame.text.price.icon.texture:SetTexture(nil)
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

            local isCurrentFocused = data.type == "item"
                and focusedMerchantSlot ~= nil
                and data.merchantSlot == focusedMerchantSlot
            frame:SetFocused(isCurrentFocused)

        end

        if scrollView.SetElementExtentCalculator then
            scrollView:SetElementExtentCalculator(function(index, elementData)
                local data = elementData
                if type(data) ~= "table" and type(index) == "table" then
                    data = index
                end

                return GetMerchantElementExtent(data)
            end)
        else
            scrollView:SetElementExtent(sectionHeight)
        end
        scrollView:SetElementInitializer("Button", Initializer, "SecureActionButtonTemplate")
    
        ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
        scrollBox:SetDataProvider(dataProvider)
        ReanchorMerchantBackground()
    end

    if not frame.FocusUpButton then
        local focusUpButton = CreateFrame("Button", "MerchantFocusUpButton", frame, "SecureActionButtonTemplate")
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
        local focusDownButton = CreateFrame("Button", "MerchantFocusDownButton", frame, "SecureActionButtonTemplate")
        frame.FocusDownButton = focusDownButton
        focusDownButton:SetAttribute("useOnKeyDown", false)
        focusDownButton:RegisterForClicks("LeftButtonUp")
        focusDownButton:SetSize(1, 1)
        focusDownButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 20)
        focusDownButton:SetScript("OnClick", function()
            MoveFocus(1)
        end)
    end

    if not frame.BuyButton then
        local buyButton = CreateFrame("Button", "MerchantBuyButton", frame, "SecureActionButtonTemplate")
        frame.BuyButton = buyButton
        buyButton:SetAttribute("useOnKeyDown", false)
        buyButton:RegisterForClicks("LeftButtonUp")
        buyButton:SetSize(1, 1)
        buyButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 40)
        buyButton:SetScript("OnClick", function()
            BuyFocusedItem()
        end)
    end

    if not frame.BuyStackButton then
        local buyStackButton = CreateFrame("Button", "MerchantBuyStackButton", frame, "SecureActionButtonTemplate")
        frame.BuyStackButton = buyStackButton
        buyStackButton:SetAttribute("useOnKeyDown", false)
        buyStackButton:RegisterForClicks("LeftButtonUp")
        buyStackButton:SetSize(1, 1)
        buyStackButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 80)
        buyStackButton:SetScript("OnClick", function()
            BuyFocusedItemStack()
        end)
    end

    if not frame.CloseButton then
        local closeButton = CreateFrame("Button", "MerchantCloseButton", frame, "SecureActionButtonTemplate")
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
            if lastFocusedMerchantSlot then
                for _, element in ipairs(dataProvider.collection) do
                    if element.type == "item" and element.merchantSlot == lastFocusedMerchantSlot then
                        targetElement = element
                        break
                    end
                end
            end

            if not targetElement then
                for _, element in ipairs(dataProvider.collection) do
                    if element.type == "item" then
                        targetElement = element
                        break
                    end
                end
            end

            if targetElement then
                UpdateFocus(targetElement, true)
            else
                focusedIndex = 1
                focusedMerchantSlot = nil
            end
            
            SetOverrideBindingClick(self.FocusUpButton, true, "PADDUP", "MerchantFocusUpButton", "LeftButton")
            SetOverrideBindingClick(self.FocusDownButton, true, "PADDDOWN", "MerchantFocusDownButton", "LeftButton")
            SetOverrideBindingClick(self.BuyButton, true, "PAD1", "MerchantBuyButton", "LeftButton")
            SetOverrideBindingClick(self.BuyStackButton, true, "PAD4", "MerchantBuyStackButton", "LeftButton")
            SetOverrideBindingClick(self.CloseButton, true, "PAD2", "MerchantCloseButton", "LeftButton")
        end)

        frame:HookScript("OnHide", function(self)
            if InCombatLockdown() then return end

            focusedMerchantSlot = nil
            focusedItemExtent = sectionHeight

            ClearOverrideBindings(self)
            if self.FocusUpButton then
                ClearOverrideBindings(self.FocusUpButton)
            end
            if self.FocusDownButton then
                ClearOverrideBindings(self.FocusDownButton)
            end
            if self.BuyButton then
                ClearOverrideBindings(self.BuyButton)
            end
            if self.BuyStackButton then
                ClearOverrideBindings(self.BuyStackButton)
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
            ClearMerchantItemTooltipDataCache()
            focusedItemExtent = sectionHeight
            dataProvider:Flush()
            return
        end

        C_Timer.After(0, function()
            LoadMerchantData()

            if focusedMerchantSlot then
                for _, element in ipairs(dataProvider.collection) do
                    if element.type == "item" and element.merchantSlot == focusedMerchantSlot then
                        UpdateFocus(element, true)
                        break
                    end
                end
            end
        end)
    end)
end


function ConsoleMenu:ShowMerchantFrame()
    local frame = ConsoleMenuFrame and ConsoleMenuFrame.MerchantFrame
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

    local scrollRange = frame.Items.ScrollBox and frame.Items.ScrollBox:GetDerivedScrollRange() or 0
    if scrollRange > 0 then
        frame.Items.ScrollBar:Show()
    else
        frame.Items.ScrollBar:Hide()
    end

    ConsoleMenu:AnimatedShow(frame)

end

function ConsoleMenu:HideMerchantFrame()
    local frame = ConsoleMenuFrame and ConsoleMenuFrame.MerchantFrame
    if not frame or not dataProvider then
        return
    end

    ConsoleMenu:AnimatedHide(frame)
end