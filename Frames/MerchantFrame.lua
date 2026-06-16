local ConsoleMenu = _G.ConsoleMenu

local dataProvider

local frameWidth = 640
local contentPadding = 0
local backdropTemplateOffset = 20

local titleSectionHeight = 32

local viewedItemCount = 3

local sectionHeight = 52
local sectionPadding = 8
local itemsSectionHeight = sectionHeight * viewedItemCount

local iconSize = sectionHeight - sectionPadding * 2
local itemFontSize = 20
local currencyIconSize = 16

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

local function UpdateMerchantActionKeys(element)
    if element and element.type == "item" then
        ConsoleMenu:AddKeysFrameItem("PAD3", "Описание предмета")
    else
        ConsoleMenu:DeleteKeysFrameItem("PAD3")
    end

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
            UpdateFocus(candidate, true)
            UpdateMerchantActionKeys(candidate)
            ConsoleMenu:UpdateKeysFrame()
            return
        end
    end

    -- Если все элементы оказались разделителями, фокус не меняем.
end

local function RemoveTooltipQuotes(text)
    if not text then
        return text
    end

    for _, quote in ipairs({
        "«", "»", '"', "'",
        "\226\128\156", -- "
        "\226\128\157", -- "
        "\226\128\152", -- '
        "\226\128\153", -- '
    }) do
        text = text:gsub(quote, "")
    end

    return text
end

local function TooltipPartNeedsSpaceSeparator(text)
    if text:match("…$") then
        return true
    end

    local lastChar = text:sub(-1)
    return lastChar == "." or lastChar == "!" or lastChar == "?"
end

local function GetFocusedItemTooltip()
    local focusedElement = GetFocusedElement()
    if not focusedElement or focusedElement.type ~= "item" then
        return nil
    end

    local merchantSlot = focusedElement.merchantSlot or focusedMerchantSlot
    if not merchantSlot then
        return nil
    end

    local tooltipData = C_TooltipInfo.GetMerchantItem(merchantSlot)
    if not tooltipData or not tooltipData.lines then
        return nil
    end

    local tooltipParts = { "Посмотрим..." }
    for _, line in ipairs(tooltipData.lines) do
        local leftText = line and line.leftText
        local containsAngleBrackets = leftText and leftText:find("<", 1, true) and leftText:find(">", 1, true)
        if leftText and leftText ~= "" and not containsAngleBrackets then
            leftText = leftText:gsub("Использование: ", "", 1)
            leftText = RemoveTooltipQuotes(leftText)
            if leftText ~= "" then
                table.insert(tooltipParts, leftText)
            end
        end
    end

    if #tooltipParts == 0 then
        return nil
    end

    local tooltipText = table.concat(tooltipParts, ". ")

    ConsoleMenu:AddSubtitles("MERCHANT_ITEM_TOOLTIP", tooltipText, UnitName("npc"))
    ConsoleMenu:SubtitleFrameUpdate()
end

function ConsoleMenu:UpdateMerchantFrameKeysFrame()
    local candidate = dataProvider.collection[focusedIndex]
    UpdateMerchantActionKeys(candidate)
end

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

local function BuyFocusedItemStack()
    if not focusedMerchantSlot then
        return
    end

    local focusedElement = GetFocusedElement()
    if not focusedElement or focusedElement.isUnavailable then
        return
    end

    local quantity = GetMerchantItemStackSize(focusedMerchantSlot)
    BuyMerchantItem(focusedMerchantSlot, quantity)
end

function ConsoleMenu:SetMerchantFrame()

    if not ConsoleMenuFrame.MerchantFrame or ConsoleMenuFrame.MerchantFrame == _G.MerchantFrame then
        local frame = CreateFrame("Frame", "ConsoleMenuMerchantFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.MerchantFrame = frame
    end

    local frame = ConsoleMenuFrame.MerchantFrame
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

    frame:SetPoint("BOTTOM", ConsoleMenuFrame, "BOTTOM", 0, 100)
    frame:SetWidth(frameWidth)
    frame:SetHeight(itemsSectionHeight)
    --frame:SetSize(frameWidth, itemsSectionHeight + contentPadding * 2 + titleSectionHeight + 32)
    frame:Hide()

    if not frame.Background then
        frame.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.Background:SetWidth(1300)
        frame.Background:SetHeight(400)
        frame.Background:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
        frame.Background:SetAtlas("LevelUp-Shadow-Upper")
        frame.Background:SetAlpha(0.9)
    end

    if not frame.Items then
        local items = CreateFrame("Frame", "MerchantFrameItems", frame)
        frame.Items = items
        items:SetAllPoints(frame)

        local scrollBox = CreateFrame("Frame", "MerchantFrameScrollBox", items, "WowScrollBoxList")
        items.ScrollBox = scrollBox
        scrollBox:SetAllPoints(items)

        local scrollBar = CreateFrame("EventFrame", "MerchantFrameScrollBar", items, "MinimalScrollBar")
        items.ScrollBar = scrollBar

        scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT")
        scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT")

        local scrollView = CreateScrollBoxListLinearView()
        dataProvider = CreateDataProvider()

        -- Инициализатор для элемента списка
        local function Initializer(frame, data)
            if not frame then return end

            -- Иконка
            if not frame.icon then
                frame.icon = CreateFrame("Frame", nil, frame)
                frame.icon:SetSize(iconSize, iconSize)
                frame.icon:SetPoint("LEFT", sectionPadding * 2, 0)
            end


            if not frame.icon.texture then
                frame.icon.texture = frame.icon:CreateTexture(nil, "ARTWORK")
                frame.icon.texture:SetAllPoints()
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

                frame.text.title = frame.text:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                frame.text.title:SetJustifyH("LEFT")
                frame.text.title:SetFont("Fonts\\FRIZQT___CYR.TTF", itemFontSize, "OUTLINE")

                frame.text.price = CreateFrame("Frame", nil, frame.text)
                frame.text.price:Hide()

                frame.text.price.text = frame.text.price:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                frame.text.price.text:SetJustifyH("RIGHT")
                frame.text.price.text:SetFont("Fonts\\FRIZQT___CYR.TTF", currencyIconSize, "OUTLINE")
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

            if not frame.bg then
                frame.bg = frame:CreateTexture(nil, "BACKGROUND")
                frame.bg:SetAllPoints()
                frame.bg:SetAtlas("Garr_BuildingInfoShadow")
                frame.bg:Hide()
            end

            if not frame.text.lines then
                frame.text.lines = {}
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
            frame.bg:Hide()
            frame.text.price.text:SetText("")
            frame.text.price:Hide()
            frame.text.price.icon.texture:SetTexture(nil)
            frame.text.price.icon:Hide()
            frame.text.price:SetHeight(0)
            for _, lineText in ipairs(frame.text.lines) do
                lineText:Hide()
                lineText:SetText("")
            end

            if not data then
                frame:SetHeight(sectionHeight)
                frame.text:Hide()
                return
            end

            frame.text:ClearAllPoints()
            frame.text:SetPoint("LEFT", frame.icon, "RIGHT", sectionPadding, 0)
            frame.text:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding, 0)
            frame.text:SetHeight(sectionHeight)

            frame.text.title:SetText(data.name or "")
            frame.text.title:ClearAllPoints()
            frame.text.title:SetPoint("LEFT", frame.text, "LEFT", 0, 0)

            if data.type == "item" then

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
                frame.text:SetPoint("LEFT", frame, "LEFT", sectionPadding * 2, 0)
                frame.text:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding, 0)
                frame.text.title:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
                frame.icon:Hide()
            else

                frame.text.title:SetTextColor(1, 0.976, 0.855, 1)
            end

            function frame:SetFocused(isFocused)
                if isFocused and data.type == "item" then
                    frame.text.title:SetTextColor(1, 0.768, 0.071, 1)
                    frame.bg:Show()
                elseif data.type == "item" then
                    frame.text.title:SetTextColor(1, 0.976, 0.855, 1)
                    frame.bg:Hide()
                else
                    frame.bg:Hide()
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
                            table.insert(formattedCostParts, string.format("x%d", costPart.value))
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

                if priceText then
                    frame.text.price.text:SetText(priceText)
                    frame.text.price.text:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding * 2, 0)

                    local titleRightAnchor = frame.text.price.text
                    if priceIconTexture and priceIconTexture ~= 0 then
                        frame.text.price.icon.texture:SetTexture(priceIconTexture)
                        frame.text.price.icon:SetPoint("RIGHT", frame.text.price.text, "LEFT", -sectionPadding, 0)
                        frame.text.price.icon:Show()
                        titleRightAnchor = frame.text.price.icon
                    else
                        frame.text.price.icon.texture:SetTexture(nil)
                        frame.text.price.icon:Hide()
                    end

                    frame.text.price:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding * 2, 0)
                    frame.text.price:SetHeight(math.max(itemFontSize, currencyIconSize))
                    frame.text.price:Show()

                    frame.text.title:ClearAllPoints()
                    frame.text.title:SetPoint("LEFT", frame.text, "LEFT", 0, 0)
                    frame.text.title:SetPoint("RIGHT", titleRightAnchor, "LEFT", -sectionPadding, 0)
                else
                    frame.text.price.icon.texture:SetTexture(nil)
                    frame.text.price.icon:Hide()
                    frame.text.price.text:SetText("")
                    frame.text.price:Hide()
                    frame.text.price:SetHeight(0)

                    frame.text.title:ClearAllPoints()
                    frame.text.title:SetPoint("LEFT", frame.text, "LEFT", 0, 0)
                end

                frame:SetHeight(sectionHeight)
                return false
            end

            local isCurrentFocused = dataProvider
                and dataProvider.collection
                and dataProvider.collection[focusedIndex] == data
            frame:SetFocused(isCurrentFocused)

        end

        scrollView:SetElementExtent(sectionHeight)
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

    if not frame.TooltipButton then
        local tooltipButton = CreateFrame("Button", "MerchantTooltipButton", frame, "SecureActionButtonTemplate")
        frame.TooltipButton = tooltipButton
        tooltipButton:SetAttribute("useOnKeyDown", false)
        tooltipButton:RegisterForClicks("LeftButtonUp")
        tooltipButton:SetSize(1, 1)
        tooltipButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 100)
        tooltipButton:SetScript("OnClick", function()
            GetFocusedItemTooltip()
        end)
    end

    if not frame.FocusBindingHooksSet then
        frame.FocusBindingHooksSet = true

        frame:HookScript("OnShow", function(self)
            SetOverrideBindingClick(self.FocusUpButton, true, "PADDUP", "MerchantFocusUpButton", "LeftButton")
            SetOverrideBindingClick(self.FocusDownButton, true, "PADDDOWN", "MerchantFocusDownButton", "LeftButton")
            SetOverrideBindingClick(self.BuyButton, true, "PAD1", "MerchantBuyButton", "LeftButton")
            SetOverrideBindingClick(self.BuyStackButton, true, "PAD4", "MerchantBuyStackButton", "LeftButton")
            SetOverrideBindingClick(self.CloseButton, true, "PAD2", "MerchantCloseButton", "LeftButton")
            SetOverrideBindingClick(self.TooltipButton, true, "PAD3", "MerchantTooltipButton", "LeftButton")
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
            if self.BuyStackButton then
                ClearOverrideBindings(self.BuyStackButton)
            end
            if self.CloseButton then
                ClearOverrideBindings(self.CloseButton)
            end
            if self.TooltipButton then
                ClearOverrideBindings(self.TooltipButton)
            end
        end)
    end

end

function ConsoleMenu:ShowMerchantFrame()
    local frame = ConsoleMenuFrame and ConsoleMenuFrame.MerchantFrame
    if not frame or not dataProvider then
        return
    end

    local blizzardMerchantFrame = _G.MerchantFrame
    if blizzardMerchantFrame then
        local children = { blizzardMerchantFrame:GetChildren() }
        for _, child in ipairs(children) do
            child:Hide()
        end

        local merchantRegions = { blizzardMerchantFrame:GetRegions() }
        for _, region in ipairs(merchantRegions) do
            if region and region.Hide then
                region:Hide()
            end
        end
    end

    dataProvider:Flush()
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

    local lastFocusedMerchantSlot = focusedMerchantSlot

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

    -- if #unavailableItems > 0 then
    --     dataProvider:Insert({
    --         type = "separator",
    --         name = "Недоступные предметы",
    --     })

    --     for _, item in ipairs(unavailableItems) do
    --         dataProvider:Insert({
    --             type = "item",
    --             isUnavailable = true,
    --             merchantSlot = item.merchantSlot,
    --             itemID = item.itemID,
    --             name = item.name,
    --             texture = item.texture,
    --             price = item.price or 0,
    --             stackCount = item.stackCount,
    --             numAvailable = item.numAvailable,
    --             isPurchasable = item.isPurchasable,
    --             isUsable = item.isUsable,
    --             hasExtendedCost = item.hasExtendedCost,
    --             currencyID = item.currencyID,
    --             spellID = item.spellID,
    --             isQuestStartItem = item.isQuestStartItem,
    --         })
    --     end
    -- end

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
    dataProvider:Flush()
    focusedMerchantSlot = nil
end