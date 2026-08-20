local ConsoleMenu = _G.ConsoleMenu

local maxItemsCount = 5

local frameWidth = 304

local sectionHeight = 56
local sectionPadding = 3
local iconSize = sectionHeight - sectionPadding * 2
local craftingQualityIconSize = iconSize / 2
local shadowOpacity = 0.7

local titleFontSize = 24
local fontSize = 18
local captionFontSize = 20

local padding = 20
local itemsPadding = padding * 1.5

local lootListBackgroundVOffset = 320
local lootListBackgroundHOffset = 720

local frameHeight = titleFontSize + itemsPadding + sectionHeight * maxItemsCount + padding * (maxItemsCount - 1) + itemsPadding + captionFontSize

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

-- Функция для добавления предмета в список
local function AddItem(itemData)
    if not itemData then
        return
    end

    local normalizedData = {
        quantity = itemData.quantity or 1,
        itemName = itemData.itemName or UNKNOWN,
        itemQuality = itemData.itemQuality or 0,
        itemTexture = itemData.itemTexture,
        craftingQuality = itemData.craftingQuality,
        isCraftingReagent = itemData.isCraftingReagent,
    }

    -- Проверяем, не является ли добавляемый предмет дубликатом
    for i = #ConsoleMenuFrame.LootListFrame.DisplayedItems, 1, -1 do
        local item = ConsoleMenuFrame.LootListFrame.DisplayedItems[i]
        if item.itemName == normalizedData.itemName
        and item.itemQuality == normalizedData.itemQuality
        and item.craftingQuality == normalizedData.craftingQuality
        and item.quantity == normalizedData.quantity
        and item.itemTexture == normalizedData.itemTexture
        then
            return
        end
    end

    -- Добавляем предмет в очередь
    table.insert(ConsoleMenuFrame.LootListFrame.Queue, {
        quantity = normalizedData.quantity,
        itemName = normalizedData.itemName,
        itemQuality = normalizedData.itemQuality,
        itemTexture = normalizedData.itemTexture,
        craftingQuality = normalizedData.craftingQuality,
        isCraftingReagent = normalizedData.isCraftingReagent,
        startTime = GetTime(),
    })
    
end

-- Функция для удаления старых предметов из очереди
local function CleanQueueGarbage()
    for i = #ConsoleMenuFrame.LootListFrame.Queue, 1, -1 do
        local item = ConsoleMenuFrame.LootListFrame.Queue[i]
        if GetTime() - item.startTime > duration then
            table.remove(ConsoleMenuFrame.LootListFrame.Queue, i)
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
local function UpdateListItemsTitle()
    local lootFrame = ConsoleMenuFrame.LootListFrame
    local displayedCount = #ConsoleMenuFrame.LootListFrame.DisplayedItems
    
    if displayedCount > 0 then
        ConsoleMenu:PlayFadeOut(PartyFrame)
        ConsoleMenu:PlayFadeOut(CompactRaidFrameContainer)
        ConsoleMenu:AnimatedShow(lootFrame.Title)
        if lootFrame.background then
            ConsoleMenu:AnimatedShow(lootFrame.background)
        end
    else
        ConsoleMenu:PlayFadeIn(PartyFrame)
        ConsoleMenu:PlayFadeIn(CompactRaidFrameContainer)
        ConsoleMenu:AnimatedHide(lootFrame.Title)
        if lootFrame.background then
            ConsoleMenu:AnimatedHide(lootFrame.background)
        end
    end

    if displayedCount == maxItemsCount and #ConsoleMenuFrame.LootListFrame.Queue > 0 then
        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.LootListFrame.AdditionalItemsCount)
    else
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.LootListFrame.AdditionalItemsCount)
    end
end

local function ReanchorLootListBackground(pendingItemFrame)
    local lootFrame = ConsoleMenuFrame and ConsoleMenuFrame.LootListFrame
    if not lootFrame or not lootFrame.background or not lootFrame.Title then
        return
    end

    local background = lootFrame.background
    background:ClearAllPoints()
    background:SetPoint("TOPLEFT", lootFrame.Title, "TOPLEFT", -lootListBackgroundHOffset * 1.5, lootListBackgroundVOffset)
    background:SetPoint("TOPRIGHT", lootFrame.Title, "TOPRIGHT", lootListBackgroundHOffset, lootListBackgroundVOffset)

    local totalItemsCount = #lootFrame.DisplayedItems + #lootFrame.Queue
    if totalItemsCount > maxItemsCount and lootFrame.AdditionalItemsCount then
        background:SetPoint("BOTTOMLEFT", lootFrame.AdditionalItemsCount, "BOTTOMLEFT", -lootListBackgroundHOffset * 1.5, -lootListBackgroundVOffset)
        background:SetPoint("BOTTOMRIGHT", lootFrame.AdditionalItemsCount, "BOTTOMRIGHT", lootListBackgroundHOffset, -lootListBackgroundVOffset * 2)
        return
    end

    local lastItem
    local lowestBottom
    if lootFrame.Items then
        for i = 1, maxItemsCount do
            local itemFrame = lootFrame.Items["Item" .. i]
            if itemFrame and (itemFrame:IsShown() or itemFrame == pendingItemFrame) then
                local bottom = itemFrame:GetBottom() or math.huge
                if not lowestBottom or bottom < lowestBottom then
                    lowestBottom = bottom
                    lastItem = itemFrame
                end
            end
        end
    end

    if lastItem then
        background:SetPoint("BOTTOMLEFT", lastItem, "BOTTOMLEFT", -lootListBackgroundHOffset, -lootListBackgroundVOffset)
        background:SetPoint("BOTTOMRIGHT", lastItem, "BOTTOMRIGHT", lootListBackgroundHOffset / 2, -lootListBackgroundVOffset)
    elseif lootFrame.AdditionalItemsCount then
        background:SetPoint("BOTTOMLEFT", lootFrame.AdditionalItemsCount, "BOTTOMLEFT", -lootListBackgroundHOffset, -lootListBackgroundVOffset)
        background:SetPoint("BOTTOMRIGHT", lootFrame.AdditionalItemsCount, "BOTTOMRIGHT", lootListBackgroundHOffset / 2, -lootListBackgroundVOffset)
    end
end

-- Функция для обновления фрейма предмета
local function UpdateItemFrame(frame, item)
    if not item then return end

    local itemName = item.itemName or UNKNOWN
    local itemQuality = item.itemQuality or 0
    local quantity = item.quantity or 1

    frame.Icon.Texture:SetTexture(item.itemTexture)
    
    if item.craftingQuality then
        frame.Icon.CraftingQuality:SetPoint("TOPLEFT", frame.Icon, "TOPLEFT", CraftingQualityOffset[item.craftingQuality][1], -CraftingQualityOffset[item.craftingQuality][2])
        
        local atlasName = CraftingQualityTexture[item.craftingQuality]

        frame.Icon.CraftingQuality:SetAtlas(atlasName)
        local atlasInfo = C_Texture.GetAtlasInfo(atlasName)

        frame.Icon.CraftingQuality:SetWidth(craftingQualityIconSize)
        frame.Icon.CraftingQuality:SetHeight(craftingQualityIconSize / atlasInfo.width * atlasInfo.height)
        
        frame.Icon.CraftingQuality:Show()
    elseif frame.Icon.CraftingQuality then
        frame.Icon.CraftingQuality:Hide()
    end

    local text = itemName

    local colorCode = ITEM_QUALITY_COLORS[itemQuality] and ITEM_QUALITY_COLORS[itemQuality].hex

    if colorCode and itemQuality >= 3 then
        text = colorCode .. text .. "|r"
    end

    if quantity > 1 then
        text = text .. " x" .. quantity
    end

    frame.Text:SetText(text)

    frame.startTime = item.startTime

    -- Добавляем в список отображаемых
    table.insert(ConsoleMenuFrame.LootListFrame.DisplayedItems, item)

    -- Удаляем из очереди на отображение
    for i = #ConsoleMenuFrame.LootListFrame.Queue, 1, -1 do
        if ConsoleMenuFrame.LootListFrame.Queue[i] == item then
            table.remove(ConsoleMenuFrame.LootListFrame.Queue, i)
        end
    end

    UpdateListItemsPoints()
    UpdateListItemsTitle()
    ReanchorLootListBackground(frame)
    ConsoleMenu:AnimatedShow(frame)

    C_Timer.After(duration, function()

        -- Если исчезает последний отображемый элемент
        if #ConsoleMenuFrame.LootListFrame.DisplayedItems == 1 then
            ConsoleMenuFrame.LootListFrame.Queue = {}
        end

        -- Удаляем из списка отображаемых
        for i = #ConsoleMenuFrame.LootListFrame.DisplayedItems, 1, -1 do
            if ConsoleMenuFrame.LootListFrame.DisplayedItems[i] == item then
                table.remove(ConsoleMenuFrame.LootListFrame.DisplayedItems, i)
            end
        end

        UpdateListItemsTitle()
        ReanchorLootListBackground()
        ConsoleMenu:AnimatedHide(frame)
    end)

end

-- Функция для обновления списка предметов
local function UpdateLootList()

    -- Находим свободные фреймы для отображения предметов
    local frames = FindItemFrames()

    -- Сортируем предметы по качеству
    table.sort(ConsoleMenuFrame.LootListFrame.Queue, function(a, b)
        return (a.itemQuality or 0) > (b.itemQuality or 0)
    end)

    -- Собираем предметы для обработки (до удаления из очереди)
    local itemsToProcess = {}
    for i = 1, math.min(#frames, #ConsoleMenuFrame.LootListFrame.Queue) do
        local item = ConsoleMenuFrame.LootListFrame.Queue[i]
        if item then
            table.insert(itemsToProcess, {frame = frames[i], item = item})
        end
    end

    -- Обрабатываем все собранные предметы
    for _, data in ipairs(itemsToProcess) do
        UpdateItemFrame(data.frame, data.item)
    end

    UpdateListItemsTitle()

end

-- Функция для инициализации LootList
function ConsoleMenu:SetLootList()

    if ConsoleMenuDB.lootFrameStyle == 1 then return end


    if not ConsoleMenuFrame.LootListFrame then
        local frame = CreateFrame("Frame", "LootListFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.LootListFrame = frame
    end

    if not ConsoleMenuFrame.LootListFrame.Queue then
        ConsoleMenuFrame.LootListFrame.Queue = {}
    end

    if not ConsoleMenuFrame.LootListFrame.DisplayedItems then
        ConsoleMenuFrame.LootListFrame.DisplayedItems = {}
    end

    local frame = ConsoleMenuFrame.LootListFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("TOPLEFT", ConsoleMenuFrame.NotificationFrame, "BOTTOMLEFT", 0, -48)

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

    -- Добавляем фон с текстурой
    if not frame.background and frame.Title and frame.AdditionalItemsCount then
        frame.background = frame:CreateTexture(nil, "BACKGROUND")
        frame.background:SetParent(frame)
        frame.background:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\CrossBackgorund.png")
        frame.background:SetDrawLayer("BACKGROUND", 0)
        ConsoleMenu:InitFadeAnimations(frame.background, animationDuration)
        frame.background:Hide()
        ReanchorLootListBackground()
    end

    -- Секции предметов
    if not frame.Items then
        frame.Items = CreateFrame("Frame", "LootListFrameItems", frame)
        frame.Items:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -itemsPadding)
        frame.Items:SetPoint("BOTTOMRIGHT", frame.AdditionalItemsCount, "TOPRIGHT", 0, itemsPadding)

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

                item.Icon.CraftingQuality = item.Icon:CreateTexture(nil, "OVERLAY")
                item.Icon.CraftingQuality:SetDrawLayer("OVERLAY", 1)
                
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
            -- if not item.Background then
            --     item.Background = item:CreateTexture(nil, "BACKGROUND")
            --     item.Background:SetPoint("TOPLEFT", item, "TOPLEFT", -32, 32)
            --     item.Background:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", 32, -24)
            --     item.Background:SetAtlas("Garr_BuildingInfoShadow")
            --     item.Background:SetAlpha(shadowOpacity)
            -- end
        end
    end

    frame:RegisterEvent("LOOT_OPENED")
    frame:RegisterEvent("TRADE_SKILL_ITEM_CRAFTED_RESULT")
    frame:RegisterEvent("QUEST_LOOT_RECEIVED")
    frame:RegisterEvent("SHOW_LOOT_TOAST")

    local function OnLootListEvent(self, event, ...)
        if event == "LOOT_OPENED" then
            -- Отображение предметов из окна добычи
            for slotIndex = 1, GetNumLootItems() do
                local itemTexture, itemName, quantity, currencyID, itemQuality, _, isQuestItem, _, _, isCoin = GetLootSlotInfo(slotIndex)
        
                if not (currencyID or isCoin) then
                    local itemLink = GetLootSlotLink(slotIndex)
                    local craftingQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemLink)

                    AddItem({
                        quantity = quantity,
                        itemName = itemName,
                        itemQuality = itemQuality,
                        itemTexture = itemTexture,
                        craftingQuality = craftingQuality,
                    })
                end

            end
        elseif event == "TRADE_SKILL_ITEM_CRAFTED_RESULT" then
            -- Отображение изготовленных предметов
            local data = ...

            if not data then return end
            
            local quantity = data.quantity
            local craftingQuality = data.craftingQuality
            local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _, _ = C_Item.GetItemInfo(data.hyperlink)
            
            AddItem({
                quantity = quantity,
                craftingQuality = craftingQuality,
                itemName = itemName,
                itemQuality = itemQuality,
                itemTexture = itemTexture,
            })
        elseif event == "QUEST_LOOT_RECEIVED" then
            -- Отображение награды за задание
            local _, itemLink, quantity = ...

            local craftingQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemLink)
            local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _, _ = C_Item.GetItemInfo(itemLink)

            AddItem({
                quantity = quantity,
                itemName = itemName,
                itemQuality = itemQuality,
                itemTexture = itemTexture,
                craftingQuality = craftingQuality,
            })
        elseif event == "SHOW_LOOT_TOAST" then
            local typeIdentifier, itemLink, quantity, _, _, _, _, _, _, _ = ...

            if typeIdentifier ~= "item" then return end

            local craftingQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemLink)
            local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _, _ = C_Item.GetItemInfo(itemLink)

            -- TODO:Тут иногда дублируются (c LOOT_OPENED) предметы при получении добычи с босса
            AddItem({
                quantity = quantity,
                itemName = itemName,
                itemQuality = itemQuality,
                itemTexture = itemTexture,
                craftingQuality = craftingQuality,
            })
        end

        UpdateLootList()
    end

    frame:SetScript("OnEvent", OnLootListEvent)
end