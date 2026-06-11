local ConsoleMenu = _G.ConsoleMenu

local dataProvider

local frameWidth = 480
local contentPadding = 40

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

        scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT")
        scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT")

        local scrollView = CreateScrollBoxListLinearView()
        dataProvider = CreateDataProvider()

        -- Инициализатор для элемента списка
        local function Initializer(frame, data)
            if not data or not frame then return end

            -- Установка иконки пункту списка
            local function SetIcon(frame, data)
                if not frame.icon then
                    frame.icon = CreateFrame("Frame", nil, frame)
                    frame.icon:SetSize(iconSize, iconSize)
                    frame.icon:SetPoint("LEFT", sectionPadding, 0)
                end

                if not frame.icon.texture then
                    frame.icon.texture = frame.icon:CreateTexture(nil, "ARTWORK")
                    frame.icon.texture:Hide()
                end

                if not frame.icon.border then
                    frame.icon.border = frame.icon:CreateTexture(nil, "OVERLAY")
                    frame.icon.border:Hide()
                else
                    frame.icon.border:Hide()
                end

                frame.icon.border:SetAtlas("plunderstorm-actionbar-slot-border")
                frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -8, 8)
                frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 8, -8)

                frame.icon.texture:SetAllPoints()
                frame.icon.texture:SetTexture(data.texture)
                ApplyMaskToTexture(frame.icon.texture)
                frame.icon.border:Show()
                frame.icon.texture:Show()
            end

            -- Иконка
            if not frame.icon then
                frame.icon = CreateFrame("Frame", nil, frame)
                frame.icon:SetSize(iconSize, iconSize)
                frame.icon:SetPoint("LEFT", 0, 0)
            end
            
            SetIcon(frame, data)

            -- Текст
            if not frame.text then
                frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                frame.text:SetPoint("LEFT", frame.icon, "RIGHT", sectionPadding * 2, -2)
                frame.text:SetPoint("RIGHT", -sectionPadding, -2)
                frame.text:SetJustifyH("LEFT")
                frame.text:SetFont("Fonts\\FRIZQT___CYR.TTF", itemFontSize, "OUTLINE")
                frame.text:SetText(data.name)
                frame.text:SetTextColor(1, 0.976, 0.855)
            end
        end

        scrollView:SetElementExtent(sectionHeight)
        scrollView:SetElementInitializer("Button", Initializer, "SecureActionButtonTemplate")
    
        ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
        scrollBox:SetDataProvider(dataProvider)
    end

    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("MERCHANT_CLOSED")

    local function OnMerchantFrameEvent(self, event, ...)
        if event == "MERCHANT_SHOW" then
            frame.Title.Text:SetText(UnitName("npc"))
            dataProvider:Flush()

            local count = GetMerchantNumItems()
            for i = 1, count do
                local info = C_MerchantFrame.GetItemInfo(i)
                if info then
                    dataProvider:Insert({
                        name = info.name,
                        texture = info.texture,
                        price = info.price or 0,
                        stackCount = info.stackCount or 0,
                        numAvailable = info.numAvailable or 0,
                        isPurchasable = info.isPurchasable or false,
                        isUsable = info.isUsable or false,
                        hasExtendedCost = info.hasExtendedCost or false,
                        currencyID = info.currencyID,
                        spellID = info.spellID,
                        isQuestStartItem = info.isQuestStartItem or false,
                    })
                end
            end

            ConsoleMenu:AnimatedShow(frame)
        elseif event == "MERCHANT_CLOSED" then
            ConsoleMenu:AnimatedHide(frame)
            dataProvider:Flush()
        end
    end

    frame:SetScript("OnEvent", OnMerchantFrameEvent)
end