local ConsoleMenu = _G.ConsoleMenu

local maxItemsCount = 5

local frameWidth = 304

local sectionHeight = 56
local sectionPadding = 2
local iconSize = sectionHeight - sectionPadding * 2
local craftingQualityIconSize = iconSize / 2

local titleFontSize = 24
local fontSize = 18
local captionFontSize = 20
local padding = 24

local frameHeight = titleFontSize + padding + sectionHeight * maxItemsCount + padding * (maxItemsCount - 1) + padding + captionFontSize

local duration = 8
local animationDuration = 0.3

-- Текстуры качества реагента для профессии
local CraftingQualityTexture = {
    [1] = "Professions-Icon-Quality-Tier1",
    [2] = "Professions-Icon-Quality-Tier2",
    [3] = "Professions-Icon-Quality-Tier3",
}

-- Смещения текстуры качества реагента для профессии по горизонтали и вертикали
local CraftingQualityOffset = {
    [1] = {0, 0},
    [2] = {4, 0},
    [3] = {4, 4},
}

-- Функция для удаления старых предметов
local function RemoveOldItems()
    for i = #ConsoleMenu.Items, 1, -1 do
        local item = ConsoleMenu.Items[i]
        if item.startTime + duration < GetTime() then
            table.remove(ConsoleMenu.Items, i)
        end
    end
end

-- Функция для обновления точек расположения предметов
local function UpdateListItemsPoints()
    if not ConsoleMenuFrame.LootListFrame or not ConsoleMenuFrame.LootListFrame.Items then
        return
    end

    local frames = {}
    for i = 1, maxItemsCount do
        local itemFrame = ConsoleMenuFrame.LootListFrame.Items["Item" .. i]
        if itemFrame then
            table.insert(frames, itemFrame)
        end
    end

    table.sort(frames, function(a, b)
        return (a.startTime or 0) > (b.startTime or 0)
    end)

    for i = 1, #frames do
        local itemFrame = frames[i]
        itemFrame:ClearAllPoints()
        itemFrame:SetPoint("TOPLEFT", ConsoleMenuFrame.LootListFrame.Items, "TOPLEFT", 0, -(sectionHeight * (i-1) + padding * (i-1)))
    end
end

-- Функция для обновления заголовков списка предметов
local function UpdateListItemsTitles()
    
    if #ConsoleMenu.Items > 0 then
        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.LootListFrame.Title)
    else
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.LootListFrame.Title)
    end

    if #ConsoleMenu.Items > 5 then
        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.LootListFrame.AdditionalItemsCount)
    else
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.LootListFrame.AdditionalItemsCount)
    end
end

-- Функция для обновления фрейма предмета
local function UpdateItemFrame(frame, item)
    if not item then return end
    
    frame.Icon.Texture:SetTexture(item.itemTexture)
    
    if item.isCraftingReagent and frame.Icon.CraftingQuality then
        frame.Icon.CraftingQuality:Show()
    elseif frame.Icon.CraftingQuality then
        frame.Icon.CraftingQuality:Hide()
    end

    local text = item.itemName

    local colorCode = ITEM_QUALITY_COLORS[item.itemQuality] and ITEM_QUALITY_COLORS[item.itemQuality].hex

    if colorCode and item.itemQuality >= 3 then
        text = colorCode .. text .. "|r"
    end

    if item.quantity > 1 then
        text = text .. " x" .. item.quantity
    end

    frame.Text:SetText(text)

    frame.startTime = item.startTime
    ConsoleMenu:AnimatedShow(frame)
    UpdateListItemsTitles()

    C_Timer.After(duration, function()

        -- Удаляем элемент из таблицы ConsoleMenu.Items с обходом в обратном порядке
        for i = #ConsoleMenu.Items, 1, -1 do
            if ConsoleMenu.Items[i] == item then
                table.remove(ConsoleMenu.Items, i)
            end
        end
        UpdateListItemsTitles()
        ConsoleMenu:AnimatedHide(frame)
    end)

end

-- Функция для поиска свободных фреймов для отображения предметов
local function FindItemFrames()
    if not ConsoleMenuFrame.LootListFrame or not ConsoleMenuFrame.LootListFrame.Items then
        return {}
    end

    local frames = {}

    for i = 1, maxItemsCount do
        local itemFrame = ConsoleMenuFrame.LootListFrame.Items["Item" .. i]
        if itemFrame and not itemFrame:IsShown() then
            table.insert(frames, itemFrame)
        end
    end

    return frames
end

-- Функция для обновления списка предметов
local function UpdateLootList()

    -- Удаляем старые предмета
    RemoveOldItems()

    -- Если нет предметов, то ничего не делаем
    if #ConsoleMenu.Items == 0 then return end

    -- Сортируем предметы по качеству
    table.sort(ConsoleMenu.Items, function(a, b)
        return (a.itemQuality or 0) > (b.itemQuality or 0)
    end)

    -- Находим свободные фреймы для отображения предметов
    local frames = FindItemFrames()
    if #frames == 0 then return end

    for i = 1, #frames do
        local frame = frames[i]
        local item = ConsoleMenu.Items[i]
        
        if item then
            UpdateItemFrame(frame, item)
        end
    end

    --  Автоматическое удаление неотображенных предметов
    local hiddenLookup = {}
    for i = #frames + 1, #ConsoleMenu.Items do
        hiddenLookup[ConsoleMenu.Items[i]] = true
    end

    C_Timer.After(duration, function()
        for i = #ConsoleMenu.Items, 1, -1 do
            if hiddenLookup[ConsoleMenu.Items[i]] then
                table.remove(ConsoleMenu.Items, i)
            end
        end
        UpdateListItemsTitles()
    end)

    UpdateListItemsPoints()
end

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
        frame.Title:SetWordWrap(true)

        ConsoleMenu:InitFadeAnimations(frame.Title, animationDuration)

        frame.Title:Hide()

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
        ConsoleMenu:InitFadeAnimations(frame.AdditionalItemsCount, animationDuration)

        frame.AdditionalItemsCount:Hide()

    end

    -- Секции предметов
    if not frame.Items then
        frame.Items = CreateFrame("Frame", "LootListFrameItems", frame)
        frame.Items:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -padding)
        frame.Items:SetPoint("BOTTOMRIGHT", frame.AdditionalItemsCount, "TOPRIGHT", 0, padding)

        for i = 1, maxItemsCount do
            local item = CreateFrame("Frame", "LootListFrameItem" .. i, frame.Items)
            frame.Items["Item" .. i] = item

            item:Hide()

            item:SetWidth(frameWidth)
            item:SetHeight(sectionHeight)
            item:SetPoint("TOPLEFT", frame.Items, "TOPLEFT", 0, -(sectionHeight * (i-1) + padding * (i-1)))
            ConsoleMenu:InitFadeAnimations(item, animationDuration)

            -- Иконка
            if not item.Icon then
                item.Icon = CreateFrame("Frame", nil, item)
                item.Icon:SetSize(iconSize, iconSize)
                item.Icon:SetPoint("LEFT", sectionPadding, 0)
            end

            if not item.Icon.Texture then
                item.Icon.Texture = item.Icon:CreateTexture(nil, "ARTWORK")
                item.Icon.Texture:SetAllPoints()
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
            if not item.Icon.CraftingQuality then

                local quality = 3
                item.Icon.CraftingQuality = item.Icon:CreateTexture(nil, "OVERLAY")
                item.Icon.CraftingQuality:SetDrawLayer("OVERLAY", 1)
                item.Icon.CraftingQuality:SetPoint("TOPLEFT", item.Icon, "TOPLEFT", CraftingQualityOffset[quality][1], -CraftingQualityOffset[quality][2])
                
                local atlasName = CraftingQualityTexture[quality]

                item.Icon.CraftingQuality:SetAtlas(atlasName)
                local atlasInfo = C_Texture.GetAtlasInfo(atlasName)

                item.Icon.CraftingQuality:SetWidth(craftingQualityIconSize)
                item.Icon.CraftingQuality:SetHeight(craftingQualityIconSize / atlasInfo.width * atlasInfo.height)
            end

            -- Текст
            if not item.Text then
                item.Text = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                item.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
                item.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
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
            for slotIndex = 1, GetNumLootItems() do
                local itemTexture, itemName, quantity, currencyID, itemQuality, _, isQuestItem, _, _, isCoin = GetLootSlotInfo(slotIndex)

                if not (currencyID or isCoin) then
                    table.insert(ConsoleMenu.Items, {
                        quantity = quantity,
                        itemName = itemName,
                        itemQuality = itemQuality,
                        itemTexture = itemTexture,
                        startTime = GetTime(),
                    })
                end

            end
        elseif event == "TRADE_SKILL_ITEM_CRAFTED_RESULT" then
            local data = ...

            if not data then return end
            
            local quantity = data.quantity
            local craftingQuality = data.craftingQuality
            local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, isCraftingReagent, _ = C_Item.GetItemInfo(data.hyperlink)
            
            table.insert(ConsoleMenu.Items, {
                quantity = quantity,
                craftingQuality = craftingQuality,
                itemName = itemName,
                itemQuality = itemQuality,
                itemTexture = itemTexture,
                isCraftingReagent = isCraftingReagent,
                startTime = GetTime(),
            })
        end

        UpdateLootList()
    end

    frame:SetScript("OnEvent", OnLootListEvent)
end