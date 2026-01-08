local ConsoleMenu = _G.ConsoleMenu

local maxItemsCount = 5

local frameWidth = 304

local sectionHeight = 56
local sectionPadding = 2
local iconSize = sectionHeight - sectionPadding * 2

local titleFontSize = 24
local fontSize = 18
local captionFontSize = 20
local padding = 24

local frameHeight = titleFontSize + padding + sectionHeight * maxItemsCount + padding * (maxItemsCount - 1) + padding + captionFontSize

local duration = 8
local animationDuration = 0.3

-- Текстуры качества реагента для профессии
local reagentQualityTexture = {
    [1] = "Professions-Icon-Quality-Tier1",
    [2] = "Professions-Icon-Quality-Tier2",
    [3] = "Professions-Icon-Quality-Tier3",
}

local reagentQualityOffset = {
    [1] = {0, 0},
    [2] = {4, 0},
    [3] = {4, 4},
}

-- Функция для инициализации LootList
function ConsoleMenu:SetLootList()
    if not ConsoleMenu.Items then
        ConsoleMenu.Items = {}
    end

    if not ConsoleMenuFrame.LootListFrame then
        local frame = CreateFrame("Frame", "LootListFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.LootListFrame = frame
    end

    local frame = ConsoleMenuFrame.LootListFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("TOPLEFT", ConsoleMenuFrame.NotificationFrame, "BOTTOMLEFT", 0, -48)
    frame:Show()
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)

    -- Заголовок
    if not frame.Title then
        frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.Title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.Title:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "")
        frame.Title:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.Title:SetJustifyH("LEFT")

        local text = COLLECTED .. " " .. ITEMS
        local title = string.sub(text, 1, 2) .. string.lower(string.sub(text, 2))
        
        frame.Title:SetText(title)
        frame.Title:SetNonSpaceWrap(true)
        frame.Title:Show()
        frame.Title:SetWordWrap(true)
    end

    -- Счетчик дополнительных предметов
    if not frame.AdditionalItemsCount then
        frame.AdditionalItemsCount = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.AdditionalItemsCount:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        frame.AdditionalItemsCount:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        frame.AdditionalItemsCount:SetFont("Fonts\\FRIZQT___CYR.TTF", captionFontSize, "")
        frame.AdditionalItemsCount:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.AdditionalItemsCount:SetJustifyH("LEFT")
        local text = "и еще несколько в инвентаре"
        frame.AdditionalItemsCount:SetText(text)
        frame.AdditionalItemsCount:Show()
    end

    -- Секции предметов
    if not frame.Items then
        frame.Items = CreateFrame("Frame", "LootListFrameItems", frame)
        frame.Items:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -padding)
        frame.Items:SetPoint("BOTTOMRIGHT", frame.AdditionalItemsCount, "TOPRIGHT", 0, padding)
        frame.Items:Show()

        for i = 1, maxItemsCount do
            local item = CreateFrame("Frame", "LootListFrameItem" .. i, frame.Items)
            frame.Items["Item" .. i] = item

            item:SetWidth(frameWidth)
            item:SetHeight(sectionHeight)
            item:SetPoint("TOPLEFT", frame.Items, "TOPLEFT", 0, -(sectionHeight * (i-1) + padding * (i-1)))

            -- Иконка
            if not item.Icon then
                item.Icon = CreateFrame("Frame", nil, item)
                item.Icon:SetSize(iconSize, iconSize)
                item.Icon:SetPoint("LEFT", sectionPadding, 0)
            end

            if not item.Icon.Texture then
                item.Icon.Texture = item.Icon:CreateTexture(nil, "ARTWORK")
                item.Icon.Texture:SetAllPoints()
                item.Icon.Texture:SetTexture(648207)
                ApplyMaskToTexture(item.Icon.Texture)
            end

            if not item.Icon.Border then
                item.Icon.Border = item.Icon:CreateTexture(nil, "OVERLAY")
                item.Icon.Border:SetPoint("TOPLEFT", item.Icon.Texture, "TOPLEFT", -2, 2)
                item.Icon.Border:SetPoint("BOTTOMRIGHT", item.Icon.Texture, "BOTTOMRIGHT", 4, -4
            )
                item.Icon.Border:SetAtlas("UI-HUD-ActionBar-IconFrame")
            end

            -- Качество реагента для профессии
            if not item.Icon.Quality then

                local quality = 3
                item.Icon.Quality = item.Icon:CreateTexture(nil, "OVERLAY")
                item.Icon.Quality:SetDrawLayer("OVERLAY", 1)
                item.Icon.Quality:SetPoint("TOPLEFT", item.Icon, "TOPLEFT", reagentQualityOffset[quality][1], -reagentQualityOffset[quality][2])
                
                local atlasName = reagentQualityTexture[quality]

                item.Icon.Quality:SetAtlas(atlasName)
                local atlasInfo = C_Texture.GetAtlasInfo(atlasName)

                item.Icon.Quality:SetWidth(iconSize / 2)
                item.Icon.Quality:SetHeight((iconSize / 2) / atlasInfo.width * atlasInfo.height)
            end

            -- Текст
            if not item.Text then
                item.Text = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                item.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
                item.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
                item.Text:SetText("Гиперкурица Гномрегана-3000БРГ х19")
                item.Text:SetPoint("LEFT", item.Icon, "RIGHT", padding, 0)
                item.Text:SetPoint("RIGHT", -padding, 0)
                item.Text:SetJustifyH("LEFT")
            end

            -- Затемнение фона
            if not item.Background then
                item.Background = item:CreateTexture(nil, "BACKGROUND")
                item.Background:SetPoint("TOPLEFT", item, "TOPLEFT", -32, 32)
                item.Background:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", 32, -24)
                item.Background:SetAtlas("Garr_BuildingInfoShadow")
                item.Background:SetAlpha(0.6)
            end
        end
    end

    frame:RegisterEvent("LOOT_OPENED")
    frame:RegisterEvent("TRADE_SKILL_ITEM_CRAFTED_RESULT")

    local function OnLootListEvent(self, event, ...)
        if event == "LOOT_OPENED" then
        elseif event == "TRADE_SKILL_ITEM_CRAFTED_RESULT" then
            local data = ...
        end
    end

    frame:SetScript("OnEvent", OnLootListEvent)
end