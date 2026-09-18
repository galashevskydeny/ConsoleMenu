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

local duration = 6
local animationDuration = 0.24
local slideOffset = 32
local iconStartScale = 0.75
local iconPeakScale = 1.06
local iconGrowDuration = 0.18
local nameDelay = 0.08
local nameSlideOffset = 22
local nameMoveDuration = 0.2
local batchStagger = 0.05
local nameOutDuration = nameMoveDuration
local nameOutFadeDuration = nameMoveDuration
local iconOutDelay = nameDelay
local iconOutDuration = iconGrowDuration
local iconOutFadeDuration = iconGrowDuration
local iconEndScale = 0.75
local titleOutFadeDuration = animationDuration
local maxAnimationStep = 0.04

-- Длительность показа строки списка добычи
function ConsoleMenu:GetLootListDisplayDuration()
    return duration
end

-- Длительность анимации заголовка и фона списка добычи
function ConsoleMenu:GetLootListAnimationDuration()
    return animationDuration
end

-- Есть ли сейчас видимые строки списка добычи
function ConsoleMenu:IsLootListShowing()
    local lootFrame = ConsoleMenuFrame and ConsoleMenuFrame.LootListFrame
    if not lootFrame or not lootFrame.DisplayedItems then
        return false
    end
    return #lootFrame.DisplayedItems > 0
end

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

-- Сохранённые сведения о слотах текущего окна добычи
local lootSlots = {}

local UpdateLootList

-- Номер предмета из ссылки, если игра его уже знает
local function GetItemIDFromLink(itemLink)
    if not itemLink then
        return nil
    end

    return C_Item.GetItemInfoInstant(itemLink)
end

-- Одинаковы ли две записи добычи
local function IsSameLootItem(left, right)
    if not left or not right then
        return false
    end

    if (left.quantity or 1) ~= (right.quantity or 1) then
        return false
    end

    if left.craftingQuality ~= right.craftingQuality then
        return false
    end

    if left.itemID and right.itemID then
        return left.itemID == right.itemID
    end

    return left.itemName == right.itemName
        and left.itemQuality == right.itemQuality
        and left.itemTexture == right.itemTexture
end

-- Уже есть такой предмет в очереди или на экране
local function HasDuplicateLootItem(itemData)
    local lootFrame = ConsoleMenuFrame and ConsoleMenuFrame.LootListFrame
    if not lootFrame then
        return false
    end

    local displayed = lootFrame.DisplayedItems
    if displayed then
        for i = 1, #displayed do
            if IsSameLootItem(displayed[i], itemData) then
                return true
            end
        end
    end

    local queue = lootFrame.Queue
    if queue then
        for i = 1, #queue do
            if IsSameLootItem(queue[i], itemData) then
                return true
            end
        end
    end

    return false
end

-- Собирает данные слота, если это предмет, а не валюта
local function BuildLootSlotData(slotIndex)
    local itemTexture, itemName, quantity, currencyID, itemQuality, _, _, _, _, isCoin = GetLootSlotInfo(slotIndex)
    if not itemName or itemName == "" or currencyID or isCoin then
        return nil
    end

    local itemLink = GetLootSlotLink(slotIndex)
    local craftingQuality
    if itemLink then
        craftingQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemLink)
    end

    return {
        quantity = quantity,
        itemName = itemName,
        itemQuality = itemQuality,
        itemTexture = itemTexture,
        craftingQuality = craftingQuality,
        itemID = GetItemIDFromLink(itemLink),
    }
end

-- Запоминает содержимое окна добычи, не показывая список
local function CacheLootSlots(replaceAll)
    if replaceAll then
        wipe(lootSlots)
    end

    for slotIndex = 1, GetNumLootItems() do
        local slotData = BuildLootSlotData(slotIndex)
        if slotData then
            lootSlots[slotIndex] = slotData
        elseif replaceAll then
            lootSlots[slotIndex] = nil
        end
    end
end

-- Обновляет один слот, если состав окна изменился
local function UpdateCachedLootSlot(slotIndex)
    if not slotIndex then
        return
    end

    lootSlots[slotIndex] = BuildLootSlotData(slotIndex)
end

-- Забывает слоты, которые не успели взять
local function ClearLootSlots()
    wipe(lootSlots)
end

-- Свободные строки: только полностью скрытые, уходящие не забираем
local function FindItemFrames()
    if not ConsoleMenuFrame.LootListFrame or not ConsoleMenuFrame.LootListFrame.Items then
        return {}
    end

    local frames = {}

    for i = 1, maxItemsCount do
        local itemFrame = ConsoleMenuFrame.LootListFrame.Items["Item" .. i]
        if itemFrame
            and not itemFrame.lootItem
            and not itemFrame:IsShown()
            and not itemFrame.pendingHide
            and not itemFrame.contentPlaying
        then
            table.insert(frames, itemFrame)
        end
    end

    return frames
end

-- Добавляет предмет в очередь показа, если это не повтор
local function AddItem(itemData)
    if not itemData then
        return
    end

    local itemName = itemData.itemName
    if not itemName or itemName == "" then
        return
    end

    local normalizedData = {
        quantity = itemData.quantity or 1,
        itemName = itemName,
        itemQuality = itemData.itemQuality or 0,
        itemTexture = itemData.itemTexture,
        craftingQuality = itemData.craftingQuality,
        isCraftingReagent = itemData.isCraftingReagent,
        itemID = itemData.itemID,
    }

    if HasDuplicateLootItem(normalizedData) then
        return
    end

    local lootFrame = ConsoleMenuFrame.LootListFrame
    lootFrame.nextAddSequence = (lootFrame.nextAddSequence or 0) + 1
    table.insert(lootFrame.Queue, {
        quantity = normalizedData.quantity,
        itemName = normalizedData.itemName,
        itemQuality = normalizedData.itemQuality,
        itemTexture = normalizedData.itemTexture,
        craftingQuality = normalizedData.craftingQuality,
        isCraftingReagent = normalizedData.isCraftingReagent,
        itemID = normalizedData.itemID,
        startTime = GetTime(),
        addSequence = lootFrame.nextAddSequence,
    })
end

-- Добавляет предмет по ссылке, когда известны имя и значок
local function AddItemFromLink(itemLink, quantity, craftingQuality)
    if not itemLink then
        return
    end

    local itemID, _, _, _, instantTexture = C_Item.GetItemInfoInstant(itemLink)
    if craftingQuality == nil then
        craftingQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemLink)
    end

    local function FinishItem(itemName, itemQuality, itemTexture)
        if not itemName or itemName == "" then
            return
        end

        AddItem({
            quantity = quantity,
            itemName = itemName,
            itemQuality = itemQuality,
            itemTexture = itemTexture or instantTexture,
            craftingQuality = craftingQuality,
            itemID = itemID,
        })
        UpdateLootList()
    end

    local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemLink)
    if itemName then
        FinishItem(itemName, itemQuality, itemTexture)
        return
    end

    local item = Item:CreateFromItemLink(itemLink)
    if not item or item:IsItemEmpty() then
        return
    end

    item:ContinueOnItemLoad(function()
        FinishItem(item:GetItemName(), item:GetItemQuality(), item:GetItemIcon())
    end)
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

-- Плавное ускорение от начала перемещения
local function EaseInQuad(progress)
    return progress * progress
end

-- Плавный разгон и замедление, без рывка в начале и в конце
local function EaseInOutQuad(progress)
    if progress < 0.5 then
        return 2 * progress * progress
    end
    local rest = 1 - progress
    return 1 - 2 * rest * rest
end

-- Масштаб значка при появлении: рост с превышением и посадка
local function IconAppearScale(progress)
    if progress < 0.7 then
        local p = EaseOutQuad(progress / 0.7)
        return iconStartScale + (iconPeakScale - iconStartScale) * p
    end
    local p = (progress - 0.7) / 0.3
    if p > 1 then
        p = 1
    end
    return iconPeakScale + (1 - iconPeakScale) * EaseOutQuad(p)
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

-- Сдвигает имя относительно значка
local function ApplyLabelSlide(itemFrame, x)
    local label = itemFrame.Label
    local holder = itemFrame.IconHolder
    if not label or not holder then
        return
    end

    itemFrame.nameSlideX = x
    label:ClearAllPoints()
    label:SetPoint("LEFT", holder, "RIGHT", padding + x, 0)
    label:SetPoint("RIGHT", itemFrame, "RIGHT", -padding, 0)
    label:SetPoint("TOP", itemFrame, "TOP", 0, 0)
    label:SetPoint("BOTTOM", itemFrame, "BOTTOM", 0, 0)
end

-- Ставит масштаб и вертикальный сдвиг значка
local function ApplyIconPose(itemFrame, scale, offsetY)
    local icon = itemFrame.Icon
    if not icon then
        return
    end

    itemFrame.iconOffsetY = offsetY or 0
    icon:SetScale(scale or 1)
    icon:ClearAllPoints()
    icon:SetPoint("CENTER", 0, itemFrame.iconOffsetY)
end

-- Возвращает значок и имя в исходное положение без движения
local function ResetContentVisuals(itemFrame, appearing)
    if appearing then
        ApplyIconPose(itemFrame, iconStartScale, 0)
        if itemFrame.Icon then
            itemFrame.Icon:SetAlpha(0)
        end
        if itemFrame.Label then
            itemFrame.Label:SetAlpha(0)
        end
        ApplyLabelSlide(itemFrame, -nameSlideOffset)
    else
        ApplyIconPose(itemFrame, 1, 0)
        if itemFrame.Icon then
            itemFrame.Icon:SetAlpha(1)
        end
        if itemFrame.Label then
            itemFrame.Label:SetAlpha(1)
        end
        ApplyLabelSlide(itemFrame, 0)
    end
end

-- Останавливает проявление или уход значка и имени
local function StopContent(itemFrame)
    if not itemFrame then
        return
    end
    itemFrame.contentPlaying = false
    itemFrame.contentMode = nil
end

-- Продвигает проявление или уход значка и имени
local function AdvanceContent(itemFrame, elapsed)
    if not itemFrame or not itemFrame.contentPlaying then
        return false
    end

    itemFrame.contentElapsed = (itemFrame.contentElapsed or 0) + elapsed
    local elapsedTime = itemFrame.contentElapsed

    if itemFrame.contentMode == "in" then
        local t = elapsedTime - (itemFrame.contentDelay or 0)
        if t < 0 then
            return true
        end

        local iconProgress = t / iconGrowDuration
        if iconProgress > 1 then
            iconProgress = 1
        end
        ApplyIconPose(itemFrame, IconAppearScale(iconProgress), 0)
        if itemFrame.Icon then
            local iconAlpha = t / iconGrowDuration
            if iconAlpha > 1 then
                iconAlpha = 1
            end
            itemFrame.Icon:SetAlpha(EaseOutQuad(iconAlpha))
        end

        local nameTime = t - nameDelay
        if nameTime < 0 then
            if itemFrame.Label then
                itemFrame.Label:SetAlpha(0)
            end
            ApplyLabelSlide(itemFrame, -nameSlideOffset)
        else
            local nameProgress = nameTime / nameMoveDuration
            if nameProgress > 1 then
                nameProgress = 1
            end
            local eased = EaseOutQuad(nameProgress)
            if itemFrame.Label then
                itemFrame.Label:SetAlpha(eased)
            end
            ApplyLabelSlide(itemFrame, -nameSlideOffset * (1 - eased))
        end

        if iconProgress >= 1 and nameTime >= nameMoveDuration then
            StopContent(itemFrame)
            ResetContentVisuals(itemFrame, false)
            return false
        end
        return true
    end

    if itemFrame.contentMode == "out" then
        -- Обратно появлению: сначала сильное гашение, сдвиг почти не читается
        local nameProgress = elapsedTime / nameOutDuration
        if nameProgress > 1 then
            nameProgress = 1
        end
        local nameMoved = EaseInQuad(nameProgress)
        local fromX = itemFrame.nameFromX or 0
        local fromNameAlpha = itemFrame.nameFromAlpha or 1
        local fadeProgress = elapsedTime / nameOutFadeDuration
        if fadeProgress > 1 then
            fadeProgress = 1
        end
        if itemFrame.Label then
            itemFrame.Label:SetAlpha(fromNameAlpha * (1 - EaseInOutQuad(fadeProgress)))
        end
        ApplyLabelSlide(itemFrame, fromX + (-nameSlideOffset - fromX) * nameMoved)

        local fromScale = itemFrame.iconFromScale or 1
        local fromIconAlpha = itemFrame.iconFromAlpha or 1
        local iconFadeProgress = elapsedTime / iconOutFadeDuration
        if iconFadeProgress > 1 then
            iconFadeProgress = 1
        end
        if itemFrame.Icon then
            itemFrame.Icon:SetAlpha(fromIconAlpha * (1 - EaseInOutQuad(iconFadeProgress)))
        end

        local iconTime = elapsedTime - iconOutDelay
        if iconTime < 0 then
            ApplyIconPose(itemFrame, fromScale, 0)
            return true
        end

        local iconProgress = iconTime / iconOutDuration
        if iconProgress > 1 then
            iconProgress = 1
        end
        local iconEased = EaseOutQuad(iconProgress)
        ApplyIconPose(
            itemFrame,
            fromScale + (iconEndScale - fromScale) * iconEased,
            0
        )

        if nameProgress >= 1 and iconProgress >= 1 then
            StopContent(itemFrame)
            itemFrame.pendingHide = true
            return false
        end
        return true
    end

    return false
end

-- Нижняя граница фона задаётся ниже и следует за последней строкой с предметом
local ReanchorLootListBackground

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
    if elapsed > maxAnimationStep then
        elapsed = maxAnimationStep
    end

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
        local itemFrame = items["Item" .. i]
        if AdvanceMotion(itemFrame, elapsed) then
            anyMoving = true
        end
        if AdvanceContent(itemFrame, elapsed) then
            anyMoving = true
        end
    end

    ReanchorLootListBackground()

    local hiddenAny = false
    if lootFrame and lootFrame.Items then
        for i = 1, maxItemsCount do
            local itemFrame = lootFrame.Items["Item" .. i]
            if itemFrame and itemFrame.pendingHide then
                itemFrame.pendingHide = nil
                StopContent(itemFrame)
                itemFrame:SetAlpha(1)
                ResetContentVisuals(itemFrame, false)
                itemFrame:Hide()
                hiddenAny = true
            end
        end
    end

    if not anyMoving then
        items:SetScript("OnUpdate", nil)
    end

    -- Очередь занимает слот только после конца ухода, иначе анимация обрывается
    if hiddenAny then
        UpdateLootList()
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
local function StartItemMotion(itemFrame, targetX, targetY, fromX, fromY, moveDuration)
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
    itemFrame.moveDuration = moveDuration or animationDuration
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

-- Начинает появление значка и имени с необязательной задержкой пачки
local function StartContentIn(itemFrame, delay)
    StopContent(itemFrame)
    itemFrame.pendingHide = nil
    itemFrame:Show()
    itemFrame:SetAlpha(1)
    ResetContentVisuals(itemFrame, true)
    itemFrame.contentMode = "in"
    itemFrame.contentElapsed = 0
    itemFrame.contentDelay = delay or 0
    itemFrame.contentPlaying = true
    EnsureItemsOnUpdate()
end

-- Начинает обратный порядок появления: имя за значок, затем толчок значка внутрь
local function StartContentOut(itemFrame)
    if not itemFrame or not itemFrame:IsShown() then
        return
    end

    itemFrame.pendingHide = nil
    itemFrame.iconFromScale = itemFrame.Icon and itemFrame.Icon:GetScale() or 1
    itemFrame.iconFromAlpha = itemFrame.Icon and itemFrame.Icon:GetAlpha() or 1
    itemFrame.iconFromY = itemFrame.iconOffsetY or 0
    itemFrame.nameFromX = itemFrame.nameSlideX or 0
    itemFrame.nameFromAlpha = itemFrame.Label and itemFrame.Label:GetAlpha() or 1
    itemFrame.contentMode = "out"
    itemFrame.contentElapsed = 0
    itemFrame.contentDelay = 0
    itemFrame.contentPlaying = true
    EnsureItemsOnUpdate()
end

-- Настраивает гашение без рывка в конце
local function PrepareFadeOut(region, fadeDuration)
    if not region or not region.fadeOut or not region.fadeOut.alpha then
        return
    end
    region.fadeOut.alpha:SetDuration(fadeDuration or animationDuration)
    region.fadeOut.alpha:SetSmoothing("IN_OUT")
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

-- Гасит надпись быстрее значков, с уходом влево
local function HideLootLabel(holder)
    if not holder or not holder:IsShown() then
        return
    end
    if holder.fadeOut and holder.fadeOut:IsPlaying() then
        return
    end

    local _, currentY = GetItemOffsets(holder)
    StartItemMotion(holder, -slideOffset, currentY, nil, nil, titleOutFadeDuration)
    PrepareFadeOut(holder, titleOutFadeDuration)
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

    local appearIndex = 0
    for i = 1, #frames do
        local itemFrame = frames[i]
        local targetY = GetItemSlotOffset(i)
        if itemFrame.enterFromLeft then
            itemFrame.enterFromLeft = nil
            -- Новая строка встаёт в слот на месте: едет только имя, не вся строка
            SnapItemMotion(itemFrame, 0, targetY)
            StartContentIn(itemFrame, appearIndex * batchStagger)
            appearIndex = appearIndex + 1
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
            PrepareFadeOut(lootFrame.background, titleOutFadeDuration)
            ConsoleMenu:AnimatedHide(lootFrame.background)
        end
    end

    if displayedCount == maxItemsCount and #ConsoleMenuFrame.LootListFrame.Queue > 0 then
        ShowLootLabel(lootFrame.AdditionalItemsCountHolder or lootFrame.AdditionalItemsCount)
    else
        HideLootLabel(lootFrame.AdditionalItemsCountHolder or lootFrame.AdditionalItemsCount)
    end
end

-- Нижняя граница фона по самой низкой видимой строке, в том числе уходящей
ReanchorLootListBackground = function()
    local lootFrame = ConsoleMenuFrame and ConsoleMenuFrame.LootListFrame
    if not lootFrame or not lootFrame.background then
        return
    end

    local background = lootFrame.background
    -- Верх держим за сам список: заголовок при уходе уезжает влево и тащил бы тень
    background:SetPoint("TOPLEFT", lootFrame, "TOPLEFT", -lootListBackgroundHOffset * 1.5, lootListBackgroundVOffset)
    background:SetPoint("TOPRIGHT", lootFrame, "TOPRIGHT", lootListBackgroundHOffset, lootListBackgroundVOffset)

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
            if itemFrame and itemFrame:IsShown() then
                local yOffset = GetItemLayoutOffset(itemFrame)
                if not lowestOffset or yOffset < lowestOffset then
                    lowestOffset = yOffset
                    lastItem = itemFrame
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
    -- Новая строка: значок вырастает, имя выезжает следом
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

        -- Уход на месте: соседи не едут вверх, пока строка ещё гаснет
        RaiseDepartingItem(frame)
        StartContentOut(frame)
        UpdateListItemsTitle()
        ReanchorLootListBackground()
    end)

end

-- Скрывает видимый список при входе в бой обычным уходом; очередь не показанной добычи сохраняется
local function HideLootListForCombat()
    local lootFrame = ConsoleMenuFrame.LootListFrame
    if not lootFrame then
        return
    end

    lootFrame.DisplayedItems = {}

    if lootFrame.Items then
        for i = 1, maxItemsCount do
            local itemFrame = lootFrame.Items["Item" .. i]
            if itemFrame then
                itemFrame.displayToken = (itemFrame.displayToken or 0) + 1
                itemFrame.lootItem = nil
                itemFrame.startTime = nil
                itemFrame.sortOrder = nil
                itemFrame.enterFromLeft = nil
                if itemFrame:IsShown() then
                    -- В бою уходим на месте, тем же движением, что и по таймеру
                    local _, currentY = GetItemOffsets(itemFrame)
                    SnapItemMotion(itemFrame, 0, currentY)
                    RaiseDepartingItem(itemFrame)
                    StartContentOut(itemFrame)
                else
                    RestoreItemLevel(itemFrame)
                    StopContent(itemFrame)
                    itemFrame.pendingHide = nil
                    ResetContentVisuals(itemFrame, false)
                end
            end
        end
    end

    UpdateListItemsTitle()
    ReanchorLootListBackground()
end

-- Есть ли ещё строки, которые гаснут после снятия с учёта
local function HasDepartingLootItems()
    local lootFrame = ConsoleMenuFrame.LootListFrame
    if not lootFrame or not lootFrame.Items then
        return false
    end

    for i = 1, maxItemsCount do
        local itemFrame = lootFrame.Items["Item" .. i]
        if itemFrame and itemFrame:IsShown() and (itemFrame.contentPlaying or itemFrame.pendingHide) then
            return true
        end
    end

    return false
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

    UpdateListItemsTitle()
    ReanchorLootListBackground()

    -- Сообщает уведомлениям, что список только что вывел новые строки
    if processedCount > 0 and ConsoleMenu.OnLootListAppeared then
        ConsoleMenu:OnLootListAppeared()
    end

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
        PrepareFadeOut(frame.TitleHolder, titleOutFadeDuration)
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
        PrepareFadeOut(frame.AdditionalItemsCountHolder, titleOutFadeDuration)
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
        PrepareFadeOut(frame.background, titleOutFadeDuration)
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

            -- Держатель значка, чтобы масштаб рос из центра
            if not item.IconHolder then
                item.IconHolder = CreateFrame("Frame", nil, item)
                item.IconHolder:SetSize(iconSize, iconSize)
                item.IconHolder:SetPoint("LEFT", sectionPadding, 0)
            end

            -- Иконка
            if not item.Icon then
                item.Icon = CreateFrame("Frame", nil, item.IconHolder)
                item.Icon:SetSize(iconSize, iconSize)
                item.Icon:SetPoint("CENTER")
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

            -- Текст в отдельной рамке: выезжает из-за значка отдельно от него
            if not item.Label then
                item.Label = CreateFrame("Frame", nil, item)
                ApplyLabelSlide(item, 0)
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
    frame:RegisterEvent("LOOT_READY")
    frame:RegisterEvent("LOOT_SLOT_CHANGED")
    frame:RegisterEvent("LOOT_SLOT_CLEARED")
    frame:RegisterEvent("LOOT_CLOSED")
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
            -- После боя очередь проявится; если уход ещё идёт, ждём его конца
            if not HasDepartingLootItems() then
                UpdateLootList()
            end
            return
        elseif event == "LOOT_OPENED" then
            CacheLootSlots(true)
            return
        elseif event == "LOOT_READY" then
            CacheLootSlots(false)
            return
        elseif event == "LOOT_SLOT_CHANGED" then
            UpdateCachedLootSlot(...)
            return
        elseif event == "LOOT_CLOSED" then
            ClearLootSlots()
            return
        elseif event == "LOOT_SLOT_CLEARED" then
            -- Слот забрали: показываем только фактически полученный предмет
            local slotIndex = ...
            local slotData = lootSlots[slotIndex]
            lootSlots[slotIndex] = nil
            if slotData then
                AddItem(slotData)
            end
        elseif event == "TRADE_SKILL_ITEM_CRAFTED_RESULT" then
            local data = ...
            if not data then
                return
            end

            AddItemFromLink(data.hyperlink, data.quantity, data.craftingQuality)
            return
        elseif event == "QUEST_LOOT_RECEIVED" then
            local _, itemLink, quantity = ...
            AddItemFromLink(itemLink, quantity)
            return
        elseif event == "SHOW_LOOT_TOAST" then
            local typeIdentifier, itemLink, quantity = ...
            if typeIdentifier ~= "item" then
                return
            end

            AddItemFromLink(itemLink, quantity)
            return
        end

        UpdateLootList()
    end

    frame:SetScript("OnEvent", OnLootListEvent)
end