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
local slideOffset = 32

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

-- Свободные строки: сначала полностью скрытые, затем те, что ещё гаснут
local function FindItemFrames()
    if not ConsoleMenuFrame.LootListFrame or not ConsoleMenuFrame.LootListFrame.Items then
        return {}
    end

    local frames = {}

    for i = 1, maxItemsCount do
        local itemFrame = ConsoleMenuFrame.LootListFrame.Items["Item" .. i]
        if itemFrame and not itemFrame.lootItem and not itemFrame:IsShown() then
            table.insert(frames, itemFrame)
        end
    end

    for i = 1, maxItemsCount do
        local itemFrame = ConsoleMenuFrame.LootListFrame.Items["Item" .. i]
        if itemFrame and not itemFrame.lootItem and itemFrame:IsShown() then
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
    local lootFrame = ConsoleMenuFrame.LootListFrame
    lootFrame.nextAddSequence = (lootFrame.nextAddSequence or 0) + 1
    table.insert(lootFrame.Queue, {
        quantity = normalizedData.quantity,
        itemName = normalizedData.itemName,
        itemQuality = normalizedData.itemQuality,
        itemTexture = normalizedData.itemTexture,
        craftingQuality = normalizedData.craftingQuality,
        isCraftingReagent = normalizedData.isCraftingReagent,
        startTime = GetTime(),
        addSequence = lootFrame.nextAddSequence,
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

-- Вертикальное смещение строки в столбике по порядковому месту
local function GetItemSlotOffset(index)
    return -(sectionHeight * (index - 1) + padding * (index - 1))
end

-- Плавное замедление к концу перемещения
local function EaseOutQuad(progress)
    return 1 - (1 - progress) * (1 - progress)
end

-- Текущие смещения строки относительно контейнера списка
local function GetItemOffsets(itemFrame)
    local x = itemFrame.moveX
    local y = itemFrame.moveY
    if x == nil or y == nil then
        local _, _, _, xOffset, yOffset = itemFrame:GetPoint(1)
        x = xOffset or 0
        y = yOffset or 0
    end
    return x, y
end

-- Вертикальное смещение строки для привязки фона
local function GetItemLayoutOffset(itemFrame)
    local yOffset = itemFrame.moveY
    if yOffset == nil then
        local _, _, _, _, pointOffset = itemFrame:GetPoint(1)
        yOffset = pointOffset or 0
    end
    return yOffset
end

-- Ставит рамку в заданную точку относительно своего контейнера
local function ApplyItemPoint(itemFrame, x, y)
    local parent = itemFrame.moveParent
    if not parent then
        parent = ConsoleMenuFrame.LootListFrame and ConsoleMenuFrame.LootListFrame.Items
    end
    if not parent then
        return
    end

    itemFrame.moveX = x
    itemFrame.moveY = y
    itemFrame:ClearAllPoints()
    if itemFrame.moveStretchHorizontal then
        local leftPoint = itemFrame.moveLeftPoint or "TOPLEFT"
        local rightPoint = itemFrame.moveRightPoint or "TOPRIGHT"
        itemFrame:SetPoint(leftPoint, parent, leftPoint, x, y)
        itemFrame:SetPoint(rightPoint, parent, rightPoint, x, y)
    else
        itemFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    end
end

-- Нижняя граница фона задаётся ниже и следует за последней строкой с предметом
local ReanchorLootListBackground
local UpdateLootList

-- Продвигает одно движение на прошедшее время; возвращает, едет ли рамка ещё
local function AdvanceMotion(itemFrame, elapsed)
    if not itemFrame or not itemFrame.isMoving then
        return false
    end

    itemFrame.moveElapsed = (itemFrame.moveElapsed or 0) + elapsed
    local moveDuration = itemFrame.moveDuration or animationDuration
    local progress = 1
    if moveDuration > 0 then
        progress = itemFrame.moveElapsed / moveDuration
    end

    local stillMoving = true
    if progress >= 1 then
        progress = 1
        itemFrame.isMoving = false
        stillMoving = false
    end

    local eased = EaseOutQuad(progress)
    local x = itemFrame.moveFromX + (itemFrame.moveToX - itemFrame.moveFromX) * eased
    local y = itemFrame.moveFromY + (itemFrame.moveToY - itemFrame.moveFromY) * eased
    ApplyItemPoint(itemFrame, x, y)
    return stillMoving
end

-- Каждый кадр приближает едущие строки и надписи к целевому месту
local function OnItemsUpdate(items, elapsed)
    local lootFrame = ConsoleMenuFrame.LootListFrame
    local anyMoving = false

    if lootFrame then
        if AdvanceMotion(lootFrame.TitleHolder, elapsed) then
            anyMoving = true
        end
        if AdvanceMotion(lootFrame.AdditionalItemsCountHolder, elapsed) then
            anyMoving = true
        end
    end

    for i = 1, maxItemsCount do
        if AdvanceMotion(items["Item" .. i], elapsed) then
            anyMoving = true
        end
    end

    ReanchorLootListBackground()

    if not anyMoving then
        items:SetScript("OnUpdate", nil)
    end
end

-- Включает покадровый пересчёт, пока хотя бы одна строка ещё едет
local function EnsureItemsOnUpdate()
    local items = ConsoleMenuFrame.LootListFrame and ConsoleMenuFrame.LootListFrame.Items
    if not items then
        return
    end

    items:SetScript("OnUpdate", OnItemsUpdate)
end

-- Направляет строку к новой точке, начиная с текущего или заданного положения
local function StartItemMotion(itemFrame, targetX, targetY, fromX, fromY)
    if fromX == nil and fromY == nil
        and itemFrame.isMoving
        and itemFrame.moveToX == targetX
        and itemFrame.moveToY == targetY
    then
        return
    end

    local currentX, currentY = GetItemOffsets(itemFrame)
    if fromX ~= nil then
        currentX = fromX
    end
    if fromY ~= nil then
        currentY = fromY
    end

    if currentX == targetX and currentY == targetY then
        itemFrame.isMoving = false
        ApplyItemPoint(itemFrame, targetX, targetY)
        return
    end

    itemFrame.moveFromX = currentX
    itemFrame.moveFromY = currentY
    itemFrame.moveToX = targetX
    itemFrame.moveToY = targetY
    itemFrame.moveElapsed = 0
    itemFrame.moveDuration = animationDuration
    itemFrame.isMoving = true
    ApplyItemPoint(itemFrame, currentX, currentY)
    EnsureItemsOnUpdate()
end

-- Поднимает уходящую строку над остальными, чтобы её не перекрывали
local function RaiseDepartingItem(itemFrame)
    local baseLevel = itemFrame.baseFrameLevel or itemFrame:GetFrameLevel()
    itemFrame:SetFrameLevel(baseLevel + 20)
end

-- Возвращает строку на обычный слой после нового показа
local function RestoreItemLevel(itemFrame)
    if itemFrame.baseFrameLevel then
        itemFrame:SetFrameLevel(itemFrame.baseFrameLevel)
    end
end

-- Мгновенно ставит строку в точку и обрывает движение
local function SnapItemMotion(itemFrame, x, y)
    itemFrame.isMoving = false
    itemFrame.moveElapsed = 0
    itemFrame.moveFromX = x
    itemFrame.moveFromY = y
    itemFrame.moveToX = x
    itemFrame.moveToY = y
    ApplyItemPoint(itemFrame, x, y)
end

-- Проявляет надпись с заездом слева
local function ShowLootLabel(holder)
    if not holder then
        return
    end

    local fadingOut = holder.fadeOut and holder.fadeOut:IsPlaying()
    if not holder:IsShown() or fadingOut then
        local y = holder.moveBaseY or 0
        StartItemMotion(holder, 0, y, -slideOffset, y)
    end
    ConsoleMenu:AnimatedShow(holder)
end

-- Гасит надпись с уходом влево
local function HideLootLabel(holder)
    if not holder or not holder:IsShown() then
        return
    end
    if holder.fadeOut and holder.fadeOut:IsPlaying() then
        return
    end

    local _, currentY = GetItemOffsets(holder)
    StartItemMotion(holder, -slideOffset, currentY)
    ConsoleMenu:AnimatedHide(holder)
end

-- Расставляет строки по устойчивому порядку показа: новые сверху, без смены мест у остальных
local function UpdateListItemsPoints()
    local lootFrame = ConsoleMenuFrame.LootListFrame
    if not lootFrame or not lootFrame.Items then
        return
    end

    local frames = {}
    for i = 1, maxItemsCount do
        local itemFrame = lootFrame.Items["Item" .. i]
        if itemFrame and itemFrame.lootItem then
            table.insert(frames, itemFrame)
        end
    end

    table.sort(frames, function(a, b)
        local orderA = a.sortOrder or 0
        local orderB = b.sortOrder or 0
        if orderA ~= orderB then
            return orderA > orderB
        end
        local sequenceA = a.addSequence or 0
        local sequenceB = b.addSequence or 0
        if sequenceA ~= sequenceB then
            return sequenceA > sequenceB
        end
        return (a.startTime or 0) > (b.startTime or 0)
    end)

    for i = 1, #frames do
        local itemFrame = frames[i]
        local targetY = GetItemSlotOffset(i)
        if itemFrame.enterFromLeft then
            itemFrame.enterFromLeft = nil
            -- Новая строка всегда выезжает в свой слот слева, даже если заготовка ещё была на экране
            if itemFrame:IsShown() then
                if itemFrame.fadeOut then
                    itemFrame.fadeOut:Stop()
                    itemFrame.fadeOut:SetScript("OnFinished", nil)
                end
                if itemFrame.fadeIn then
                    itemFrame.fadeIn:Stop()
                end
                itemFrame:Hide()
                itemFrame:SetAlpha(0)
            end
            StartItemMotion(itemFrame, 0, targetY, -slideOffset, targetY)
        else
            StartItemMotion(itemFrame, 0, targetY)
        end
    end
end

-- Функция для обновления заголовков списка предметов
local function UpdateListItemsTitle()
    local lootFrame = ConsoleMenuFrame.LootListFrame
    local displayedCount = #ConsoleMenuFrame.LootListFrame.DisplayedItems
    
    if displayedCount > 0 then
        ConsoleMenu:PlayFadeOut(PartyFrame)
        ConsoleMenu:PlayFadeOut(CompactRaidFrameContainer)
        ShowLootLabel(lootFrame.TitleHolder or lootFrame.Title)
        if lootFrame.background then
            ConsoleMenu:AnimatedShow(lootFrame.background)
        end
    else
        ConsoleMenu:PlayFadeIn(PartyFrame)
        ConsoleMenu:PlayFadeIn(CompactRaidFrameContainer)
        HideLootLabel(lootFrame.TitleHolder or lootFrame.Title)
        if lootFrame.background then
            ConsoleMenu:AnimatedHide(lootFrame.background)
        end
    end

    if displayedCount == maxItemsCount and #ConsoleMenuFrame.LootListFrame.Queue > 0 then
        ShowLootLabel(lootFrame.AdditionalItemsCountHolder or lootFrame.AdditionalItemsCount)
    else
        HideLootLabel(lootFrame.AdditionalItemsCountHolder or lootFrame.AdditionalItemsCount)
    end
end

-- Нижняя граница фона по последней строке с предметом, иначе по ещё видимой уходящей
ReanchorLootListBackground = function()
    local lootFrame = ConsoleMenuFrame and ConsoleMenuFrame.LootListFrame
    if not lootFrame or not lootFrame.background or not lootFrame.Title then
        return
    end

    local background = lootFrame.background
    background:ClearAllPoints()
    background:SetPoint("TOPLEFT", lootFrame.Title, "TOPLEFT", -lootListBackgroundHOffset * 1.5, lootListBackgroundVOffset)
    background:SetPoint("TOPRIGHT", lootFrame.Title, "TOPRIGHT", lootListBackgroundHOffset, lootListBackgroundVOffset)

    local displayedCount = #lootFrame.DisplayedItems
    local captionVisible = displayedCount == maxItemsCount and #lootFrame.Queue > 0
    if captionVisible and lootFrame.AdditionalItemsCount then
        background:SetPoint("BOTTOMLEFT", lootFrame.AdditionalItemsCount, "BOTTOMLEFT", -lootListBackgroundHOffset * 1.5, -lootListBackgroundVOffset)
        background:SetPoint("BOTTOMRIGHT", lootFrame.AdditionalItemsCount, "BOTTOMRIGHT", lootListBackgroundHOffset, -lootListBackgroundVOffset * 2)
        return
    end

    local lastItem
    local lowestOffset
    if lootFrame.Items then
        for i = 1, maxItemsCount do
            local itemFrame = lootFrame.Items["Item" .. i]
            if itemFrame and itemFrame.lootItem then
                local yOffset = GetItemLayoutOffset(itemFrame)
                if not lowestOffset or yOffset < lowestOffset then
                    lowestOffset = yOffset
                    lastItem = itemFrame
                end
            end
        end
        if not lastItem then
            for i = 1, maxItemsCount do
                local itemFrame = lootFrame.Items["Item" .. i]
                if itemFrame and itemFrame:IsShown() then
                    local yOffset = GetItemLayoutOffset(itemFrame)
                    if not lowestOffset or yOffset < lowestOffset then
                        lowestOffset = yOffset
                        lastItem = itemFrame
                    end
                end
            end
        end
    end

    if lastItem then
        background:SetPoint("BOTTOMLEFT", lastItem, "BOTTOMLEFT", -lootListBackgroundHOffset, -lootListBackgroundVOffset)
        background:SetPoint("BOTTOMRIGHT", lastItem, "BOTTOMRIGHT", lootListBackgroundHOffset / 2, -lootListBackgroundVOffset)
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

    RestoreItemLevel(frame)
    frame.startTime = item.startTime
    frame.addSequence = item.addSequence
    frame.sortOrder = nil
    frame.lootItem = item
    -- Новая строка выезжает слева на своё место в столбике
    frame.enterFromLeft = true
    frame.displayToken = (frame.displayToken or 0) + 1
    local displayToken = frame.displayToken

    -- Добавляем в список отображаемых
    table.insert(ConsoleMenuFrame.LootListFrame.DisplayedItems, item)

    -- Удаляем из очереди на отображение
    for i = #ConsoleMenuFrame.LootListFrame.Queue, 1, -1 do
        if ConsoleMenuFrame.LootListFrame.Queue[i] == item then
            table.remove(ConsoleMenuFrame.LootListFrame.Queue, i)
        end
    end

    C_Timer.After(duration, function()
        -- Таймер с прошлого показа не должен трогать уже скрытую или заменённую строку
        if frame.displayToken ~= displayToken then
            return
        end

        -- Если исчезает последний отображаемый элемент вне боя, очередь больше не нужна
        if #ConsoleMenuFrame.LootListFrame.DisplayedItems == 1 and not InCombatLockdown() then
            ConsoleMenuFrame.LootListFrame.Queue = {}
        end

        -- Удаляем из списка отображаемых
        for i = #ConsoleMenuFrame.LootListFrame.DisplayedItems, 1, -1 do
            if ConsoleMenuFrame.LootListFrame.DisplayedItems[i] == item then
                table.remove(ConsoleMenuFrame.LootListFrame.DisplayedItems, i)
            end
        end

        frame.lootItem = nil
        frame.startTime = nil
        frame.sortOrder = nil
        frame.enterFromLeft = nil

        -- Уходящая строка гаснет и слегка уезжает влево, остальные сразу поднимаются
        local _, currentY = GetItemOffsets(frame)
        RaiseDepartingItem(frame)
        StartItemMotion(frame, -slideOffset, currentY)
        ConsoleMenu:AnimatedHide(frame)
        -- Одну перестановку делает обновление списка, без предварительного уплотнения
        UpdateLootList()
    end)

end

-- Скрывает видимый список при входе в бой и сохраняет очередь не показанной добычи
local function HideLootListForCombat()
    local lootFrame = ConsoleMenuFrame.LootListFrame
    if not lootFrame then
        return
    end

    lootFrame.DisplayedItems = {}

    if lootFrame.Items then
        lootFrame.Items:SetScript("OnUpdate", nil)
        for i = 1, maxItemsCount do
            local itemFrame = lootFrame.Items["Item" .. i]
            if itemFrame then
                itemFrame.displayToken = (itemFrame.displayToken or 0) + 1
                itemFrame.lootItem = nil
                itemFrame.startTime = nil
                itemFrame.sortOrder = nil
                itemFrame.enterFromLeft = nil
                -- Остаёмся на текущей высоте, без скачка к номеру заготовки
                local _, currentY = GetItemOffsets(itemFrame)
                SnapItemMotion(itemFrame, 0, currentY)
                RestoreItemLevel(itemFrame)
                ConsoleMenu:AnimatedHide(itemFrame)
            end
        end
    end

    if lootFrame.TitleHolder then
        SnapItemMotion(lootFrame.TitleHolder, 0, lootFrame.TitleHolder.moveBaseY or 0)
    end
    if lootFrame.AdditionalItemsCountHolder then
        SnapItemMotion(lootFrame.AdditionalItemsCountHolder, 0, lootFrame.AdditionalItemsCountHolder.moveBaseY or 0)
    end

    UpdateListItemsTitle()
    ReanchorLootListBackground()
end

-- Функция для обновления списка предметов
UpdateLootList = function()
    -- Во время боя список не показываем: предметы остаются в очереди до конца боя
    if InCombatLockdown() then
        return
    end

    -- Находим свободные фреймы для отображения предметов
    local frames = FindItemFrames()

    -- Сортируем предметы по качеству, при равенстве — по порядку получения
    table.sort(ConsoleMenuFrame.LootListFrame.Queue, function(a, b)
        local qualityA = a.itemQuality or 0
        local qualityB = b.itemQuality or 0
        if qualityA ~= qualityB then
            return qualityA > qualityB
        end
        return (a.addSequence or 0) > (b.addSequence or 0)
    end)

    -- Собираем предметы для обработки (до удаления из очереди)
    local itemsToProcess = {}
    for i = 1, math.min(#frames, #ConsoleMenuFrame.LootListFrame.Queue) do
        local item = ConsoleMenuFrame.LootListFrame.Queue[i]
        if item then
            table.insert(itemsToProcess, {frame = frames[i], item = item})
        end
    end

    -- Сначала заполняем строки и ставим их на места, затем проявляем
    for _, data in ipairs(itemsToProcess) do
        UpdateItemFrame(data.frame, data.item)
    end

    local processedCount = #itemsToProcess
    if processedCount > 0 then
        local lootFrame = ConsoleMenuFrame.LootListFrame
        local baseOrder = lootFrame.nextSortOrder or 0
        for i, data in ipairs(itemsToProcess) do
            -- В одной пачке выше оказываются предметы, взятые из очереди первыми
            data.frame.sortOrder = baseOrder + (processedCount - i + 1)
        end
        lootFrame.nextSortOrder = baseOrder + processedCount
    end

    UpdateListItemsPoints()

    if processedCount > 0 then
        for _, data in ipairs(itemsToProcess) do
            ConsoleMenu:AnimatedShow(data.frame)
        end
    end

    UpdateListItemsTitle()
    ReanchorLootListBackground()

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

    -- Заголовок в отдельной рамке: анимация прозрачности на тексте не действует
    if not frame.TitleHolder then
        frame.TitleHolder = CreateFrame("Frame", nil, frame)
        frame.TitleHolder:SetHeight(titleFontSize)
        frame.TitleHolder.moveParent = frame
        frame.TitleHolder.moveStretchHorizontal = true
        frame.TitleHolder.moveLeftPoint = "TOPLEFT"
        frame.TitleHolder.moveRightPoint = "TOPRIGHT"
        frame.TitleHolder.moveBaseY = 0
        SnapItemMotion(frame.TitleHolder, 0, 0)
        ConsoleMenu:InitFadeAnimations(frame.TitleHolder, animationDuration)
        frame.TitleHolder:Hide()
    end

    if not frame.Title then
        frame.Title = frame.TitleHolder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Title:SetAllPoints()
        frame.Title:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "")
        frame.Title:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.Title:SetJustifyH("LEFT")

        local text = COLLECTED .. " " .. ITEMS
        local title = string.sub(text, 1, 2) .. string.lower(string.sub(text, 2))
        
        frame.Title:SetText(title)
        frame.Title:SetNonSpaceWrap(true)
        frame.Title:SetWordWrap(true)
        frame.Title:SetIgnoreParentAlpha(false)
    end

    -- Подпись о дополнительных предметах в отдельной рамке
    if not frame.AdditionalItemsCountHolder then
        frame.AdditionalItemsCountHolder = CreateFrame("Frame", nil, frame)
        frame.AdditionalItemsCountHolder:SetHeight(captionFontSize)
        frame.AdditionalItemsCountHolder.moveParent = frame
        frame.AdditionalItemsCountHolder.moveStretchHorizontal = true
        frame.AdditionalItemsCountHolder.moveLeftPoint = "BOTTOMLEFT"
        frame.AdditionalItemsCountHolder.moveRightPoint = "BOTTOMRIGHT"
        frame.AdditionalItemsCountHolder.moveBaseY = 0
        SnapItemMotion(frame.AdditionalItemsCountHolder, 0, 0)
        ConsoleMenu:InitFadeAnimations(frame.AdditionalItemsCountHolder, animationDuration)
        frame.AdditionalItemsCountHolder:Hide()
    end

    if not frame.AdditionalItemsCount then
        frame.AdditionalItemsCount = frame.AdditionalItemsCountHolder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.AdditionalItemsCount:SetAllPoints()
        frame.AdditionalItemsCount:SetFont("Fonts\\FRIZQT___CYR.TTF", captionFontSize, "")
        frame.AdditionalItemsCount:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.AdditionalItemsCount:SetJustifyH("LEFT")
        local text = "и еще несколько в инвентаре"
        frame.AdditionalItemsCount:SetText(text)
        frame.AdditionalItemsCount:SetIgnoreParentAlpha(false)
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
        frame.Items:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -(titleFontSize + itemsPadding))
        frame.Items:SetPoint("BOTTOMRIGHT", frame.AdditionalItemsCount, "TOPRIGHT", 0, itemsPadding)

        for i = 1, maxItemsCount do
            local item = CreateFrame("Frame", "LootListFrameItem" .. i, frame.Items)
            frame.Items["Item" .. i] = item

            item:Hide()

            item:SetWidth(frameWidth)
            item:SetHeight(sectionHeight)
            SnapItemMotion(item, 0, GetItemSlotOffset(i))
            item.baseFrameLevel = item:GetFrameLevel()
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

            -- Текст в отдельной рамке, чтобы проявление строки на него действовало
            if not item.Label then
                item.Label = CreateFrame("Frame", nil, item)
                item.Label:SetPoint("LEFT", item.Icon, "RIGHT", padding, 0)
                item.Label:SetPoint("RIGHT", item, "RIGHT", -padding, 0)
                item.Label:SetPoint("TOP", item, "TOP", 0, 0)
                item.Label:SetPoint("BOTTOM", item, "BOTTOM", 0, 0)
            end

            if not item.Text then
                item.Text = item.Label:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                item.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
                item.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
                item.Text:SetAllPoints()
                item.Text:SetJustifyH("LEFT")
                item.Text:SetJustifyV("MIDDLE")
                item.Text:SetIgnoreParentAlpha(false)
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
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")

    local function OnLootListEvent(self, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            HideLootListForCombat()
            return
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- После окончания боя показываем накопленную очередь
            UpdateLootList()
            return
        elseif event == "LOOT_OPENED" then
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