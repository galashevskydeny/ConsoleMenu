local ConsoleMenu = _G.ConsoleMenu

local dataProvider

local frameWidth = 520
local contentPadding = 48

local titleSectionHeight = 32
local titleFontSize = 24

local viewedItemCount = 10
local sectionHeight = 56
local sectionPadding = 8
local unfocusedItemTextAlpha = 0.7
local itemsSectionHeight = sectionHeight * viewedItemCount

local iconSize = sectionHeight - sectionPadding * 2
local itemFontSize = 14
local descriptionFontSize = 12

local focusedIndex = 1
local focusedMerchantSlot = nil

local animationDuration = 0.1

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
    focusedMerchantSlot = (element.type == "item") and element.merchantSlot or nil

    if changeFocus then
        scrollBox:ScrollToElementDataIndex(focusedIndex)
    end

    local focusedFrame = scrollBox:FindFrameByPredicate(function(listItemFrame, elementData)
        return elementData == element
    end)

    if focusedFrame and focusedFrame.SetFocused and changeFocus then
        layoutChanged = focusedFrame:SetFocused(true) or layoutChanged
    end

    if layoutChanged then
        RefreshMerchantScrollLayout()
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
            UpdateFocus(candidate, true)
            return
        end
    end

    -- Если все элементы оказались разделителями, фокус не меняем.
end

local function BuyFocusedItem()
    if not focusedMerchantSlot then
        return
    end

    BuyMerchantItem(focusedMerchantSlot)
end

function ConsoleMenu:SetMerchantFrame()

    if not ConsoleMenuFrame.MerchantFrame then
        local frame = CreateFrame("Frame", "MerchantFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.MerchantFrame = frame
    end

    local frame = ConsoleMenuFrame.MerchantFrame
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

    frame:SetPoint("TOPLEFT", ConsoleMenuFrame, "TOPLEFT", 448, -48)
    frame:SetSize(frameWidth, itemsSectionHeight + contentPadding * 2 + titleSectionHeight + 22)
    frame:Hide()

    if not frame.Background then
        local background = CreateFrame("Frame", "MerchantFrameBackground", frame, "BackdropTemplate")
        frame.Background = background
        background:SetFrameStrata("BACKGROUND")
        background:SetAllPoints(frame)
        NineSliceUtil.ApplyLayoutByName(background, "CharacterCreateDropdown")
        background:SetAlpha(0.8)
    end

    if not frame.Title then
        local title = CreateFrame("Frame", "MerchantFrameTitle", frame)
        frame.Title = title
        title:SetPoint("TOPLEFT", frame, "TOPLEFT", contentPadding, -contentPadding)
        title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -contentPadding, -contentPadding)
        title:SetHeight(titleSectionHeight)

        if not frame.Title.Text then
            local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.Title.Text = text
            text:SetPoint("TOPLEFT", frame.Title, "TOPLEFT", 0, 0)
            text:SetPoint("TOPRIGHT", frame.Title, "TOPRIGHT", 0, 0)
            text:SetJustifyH("LEFT")
            text:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "")
            text:SetTextColor(1.0, 0.82, 0, 1)
            text:SetText("Продавец")
        end
    end

    if not frame.Items then
        local items = CreateFrame("Frame", "MerchantFrameItems", frame)
        frame.Items = items
        items:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -sectionPadding)
        items:SetPoint("TOPRIGHT", frame.Title, "BOTTOMRIGHT", 0, -sectionPadding)
        items:SetHeight(itemsSectionHeight)

        local scrollBox = CreateFrame("Frame", "MerchantFrameScrollBox", items, "WowScrollBoxList")
        items.ScrollBox = scrollBox
        scrollBox:SetAllPoints(items)

        local scrollBar = CreateFrame("EventFrame", "MerchantFrameScrollBar", items, "MinimalScrollBar")
        items.ScrollBar = scrollBar

        scrollBar:SetPoint("TOPRIGHT", scrollBox, "TOPRIGHT")
        scrollBar:SetPoint("BOTTOMRIGHT", scrollBox, "BOTTOMRIGHT")

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
                frame.icon.texture:SetAllPoints()
                ApplyMaskToTexture(frame.icon.texture)
            end

            if not frame.icon.border then
                frame.icon.border = frame.icon:CreateTexture(nil, "OVERLAY")
                frame.icon.border:SetAtlas("plunderstorm-actionbar-slot-border")
                frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -8, 8)
                frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 8, -8)
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
                local hasVisibleLines = false
                for _, lineText in ipairs(frame.text.lines) do
                    if lineText:IsShown() then
                        hasVisibleLines = true
                        local lineHeight = lineText:GetStringHeight()
                        if lineHeight <= 0 then
                            lineHeight = descriptionFontSize
                        end
                        totalHeight = totalHeight + lineHeight + 1
                    end
                end

                if hasVisibleLines then
                    totalHeight = totalHeight + 2
                end

                frame.text.height = totalHeight
                frame.text:SetHeight(totalHeight)
            end

            -- Жесткий reset визуального состояния обязателен:
            -- ScrollBox переиспользует один и тот же frame для разных данных.
            frame.text.title:SetText("")
            frame.text:Show()
            frame.text.title:SetTextColor(1, 0.976, 0.855, 1)
            frame.icon:Show()
            frame.icon.texture:SetTexture(nil)
            frame.icon.texture:SetDesaturated(false)
            frame.icon.texture:Hide()
            frame.icon.border:Hide()
            frame.icon.overlay:Hide()
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
                    UpdateTextHeight()
                    local wasDynamic = data.focusedHeight ~= nil
                    data.focusedHeight = nil
                    return wasDynamic
                end

                local tooltipData = C_TooltipInfo.GetMerchantItem(data.merchantSlot)
                if not tooltipData or not tooltipData.lines then
                    frame.text:SetAlpha(1)
                    UpdateTextHeight()
                    local focusedHeight = math.max(sectionHeight, (frame.text.height or sectionHeight))
                    frame:SetHeight(focusedHeight)
                    if focusedHeight > sectionHeight then
                        ApplyExpandedItemLayout()
                    else
                        ApplyDefaultItemLayout()
                    end
                    local changed = data.focusedHeight ~= focusedHeight
                    data.focusedHeight = focusedHeight
                    return changed
                end

                frame.text:SetAlpha(1)
                local lineIndex = 1
                for tooltipLineIndex = 2, #tooltipData.lines do
                    local tooltipLine = tooltipData.lines[tooltipLineIndex]
                    local leftText = tooltipLine and tooltipLine.leftText
                    if leftText and leftText ~= "" then
                        local lineText = frame.text.lines[lineIndex]
                        if not lineText then
                            lineText = frame.text:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                            frame.text.lines[lineIndex] = lineText
                            lineText:SetJustifyH("LEFT")
                            lineText:SetFont("Fonts\\FRIZQT___CYR.TTF", descriptionFontSize, "")
                        end

                        lineText:ClearAllPoints()
                        if lineIndex == 1 then
                            lineText:SetPoint("TOPLEFT", frame.text.title, "BOTTOMLEFT", 0, -3)
                            lineText:SetPoint("TOPRIGHT", frame.text.title, "BOTTOMRIGHT", 0, -3)
                        else
                            lineText:SetPoint("TOPLEFT", frame.text.lines[lineIndex - 1], "BOTTOMLEFT", 0, -1)
                            lineText:SetPoint("TOPRIGHT", frame.text.lines[lineIndex - 1], "BOTTOMRIGHT", 0, -1)
                        end

                        lineText:SetText(leftText)
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
                UpdateTextHeight()

                local focusedHeight = math.max(sectionHeight, (frame.text.height or sectionHeight) + sectionPadding * 4)
                frame:SetHeight(focusedHeight)
                if focusedHeight > sectionHeight then
                    ApplyExpandedItemLayout()
                else
                    ApplyDefaultItemLayout()
                end
                local changed = data.focusedHeight ~= focusedHeight
                data.focusedHeight = focusedHeight
                return changed
            end

            frame:SetFocused(false)

        end

        if scrollView.SetElementExtentCalculator then
            scrollView:SetElementExtentCalculator(function(index, elementData)
                local data = elementData
                if type(data) ~= "table" and type(index) == "table" then
                    data = index
                end

                local focusedHeight = data and data.focusedHeight or sectionHeight
                return math.max(sectionHeight, focusedHeight)
            end)
        else
            scrollView:SetElementExtent(sectionHeight)
        end
        scrollView:SetElementInitializer("Button", Initializer, "SecureActionButtonTemplate")
    
        ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
        scrollBox:SetDataProvider(dataProvider)
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

    if not frame.FocusBindingHooksSet then
        frame.FocusBindingHooksSet = true

        frame:HookScript("OnShow", function(self)
            SetOverrideBindingClick(self.FocusUpButton, true, "PADDUP", "MerchantFocusUpButton", "LeftButton")
            SetOverrideBindingClick(self.FocusDownButton, true, "PADDDOWN", "MerchantFocusDownButton", "LeftButton")
            SetOverrideBindingClick(self.BuyButton, true, "PAD1", "MerchantBuyButton", "LeftButton")

            local firstElement = dataProvider and dataProvider.collection[focusedIndex]
            if not firstElement and dataProvider then
                focusedIndex = 1
                firstElement = dataProvider.collection[focusedIndex]
            end

            if firstElement then
                UpdateFocus(firstElement, true)
            end
        end)

        frame:HookScript("OnHide", function(self)
            if InCombatLockdown() then return end

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
        end)
    end

    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("MERCHANT_UPDATE")
    frame:RegisterEvent("MERCHANT_CLOSED")

    local function OnMerchantFrameEvent(self, event, ...)
        if event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE" then
            C_Timer.After(0, function()
                frame.Title.Text:SetText(UnitName("npc"))
                dataProvider:Flush()
                C_Timer.After(0, function()
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
                    
                    for _, item in ipairs(availableItems) do
                        dataProvider:Insert({
                            type = "item",
                            isUnavailable = false,
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
                        })
                    end

                    if #unavailableItems > 0 then
                        dataProvider:Insert({
                            type = "separator",
                            name = "Недоступные предметы",
                        })
            
                        for _, item in ipairs(unavailableItems) do
                            dataProvider:Insert({
                                type = "item",
                                isUnavailable = true,
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
                            })
                        end
                    end

                    local count = dataProvider:GetSize()
                    if count <= viewedItemCount then
                        frame.Items.ScrollBar:Hide()
                    else
                        frame.Items.ScrollBar:Show()
                    end

                    focusedIndex = 1
                    local firstElement = dataProvider.collection[focusedIndex]
                    if firstElement then
                        UpdateFocus(firstElement, true)
                    end

                    ConsoleMenu:AnimatedShow(frame)
                end)
            end)
        elseif event == "MERCHANT_CLOSED" then
            ConsoleMenu:AnimatedHide(frame)
            dataProvider:Flush()
            focusedMerchantSlot = nil
        end
    end

    frame:SetScript("OnEvent", OnMerchantFrameEvent)
end