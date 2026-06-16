local ConsoleMenu = _G.ConsoleMenu

local dataProvider

local frameWidth = 520
local contentPadding = 48

local titleSectionHeight = 32
local titleFontSize = 24

local viewedItemCount = 10
local sectionHeight = 56
local sectionPadding = 8
local itemsSectionHeight = sectionHeight * viewedItemCount

local iconSize = sectionHeight - sectionPadding * 2
local itemFontSize = 14

local animationDuration = 0.1

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
                frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                frame.text:SetJustifyH("LEFT")
                frame.text:SetFont("Fonts\\FRIZQT___CYR.TTF", itemFontSize, "OUTLINE")
            end

            -- Жесткий reset визуального состояния обязателен:
            -- ScrollBox переиспользует один и тот же frame для разных данных.
            frame.text:SetText("")
            frame.text:Show()
            frame.text:SetTextColor(1, 0.976, 0.855, 1)
            frame.icon:Show()
            frame.icon.texture:SetTexture(nil)
            frame.icon.texture:Hide()
            frame.icon.border:Hide()
            frame.icon.overlay:Hide()

            if not data then
                frame.text:Hide()
                return
            end

            frame.text:SetText(data.name or "")

            if data.type == "item" then
                frame.text:ClearAllPoints()
                frame.text:SetPoint("LEFT", frame.icon, "RIGHT", sectionPadding * 2, -2)
                frame.text:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding * 4, -2)
                frame.text:SetTextColor(1, 0.976, 0.855, 1)

                frame.icon.texture:SetTexture(data.texture)
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
                frame.text:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
                frame.icon:Hide()
            else
                -- Неизвестный тип: оставляем безопасный базовый текстовый стиль.
                frame.text:ClearAllPoints()
                frame.text:SetPoint("LEFT", frame.icon, "RIGHT", sectionPadding * 2, -2)
                frame.text:SetPoint("RIGHT", frame, "RIGHT", -sectionPadding * 4, -2)
                frame.text:SetTextColor(1, 0.976, 0.855, 1)
            end

        end

        scrollView:SetElementExtent(sectionHeight)
        scrollView:SetElementInitializer("Button", Initializer, "SecureActionButtonTemplate")
    
        ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
        scrollBox:SetDataProvider(dataProvider)
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

                    ConsoleMenu:AnimatedShow(frame)
                end)
            end)
        elseif event == "MERCHANT_CLOSED" then
            ConsoleMenu:AnimatedHide(frame)
            dataProvider:Flush()
        end
    end

    frame:SetScript("OnEvent", OnMerchantFrameEvent)
end