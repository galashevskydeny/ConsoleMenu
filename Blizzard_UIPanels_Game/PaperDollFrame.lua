-- CharacterFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")

local offsetX = 40
local offsetY = 40
local g_selectedIndex = 1
local paperDollSidebarFocus = false
local statItems = {}
local titleItems = {}
local currentSlotIndex = nil
local currentTitleIndex = 1
local currentStatIndex = nil
local showSlotsWithStat = false
local currentEquipmentFlyoutIndex = nil

local inventorySlots = {
    CharacterHeadSlot,
    CharacterNeckSlot,
    CharacterShoulderSlot,
    CharacterBackSlot,
    CharacterChestSlot,
    CharacterShirtSlot,
    CharacterTabardSlot,
    CharacterWristSlot,
    CharacterMainHandSlot,
    CharacterSecondaryHandSlot,
    CharacterHandsSlot,
    CharacterWaistSlot,
    CharacterLegsSlot,
    CharacterFeetSlot,
    CharacterFinger0Slot,
    CharacterFinger1Slot,
    CharacterTrinket0Slot,
    CharacterTrinket1Slot,
}

local slotsIDs = {
    [1] = CharacterHeadSlot,
    [2] = CharacterNeckSlot,
    [3] = CharacterShoulderSlot,
    [15] = CharacterBackSlot,
    [5] = CharacterChestSlot,
    [4] = CharacterShirtSlot,
    [19] = CharacterTabardSlot,
    [9] = CharacterWristSlot,
    [16] = CharacterMainHandSlot,
    [17] = CharacterSecondaryHandSlot,
    [10] = CharacterHandsSlot,
    [6] = CharacterWaistSlot,
    [7] = CharacterLegsSlot,
    [8] = CharacterFeetSlot,
    [11] = CharacterFinger0Slot,
    [12] = CharacterFinger1Slot,
    [13] = CharacterTrinket0Slot,
    [14] = CharacterTrinket1Slot
}

-- Перемещение и изменение тточек привязки фреймов
local function moveFrames()

    -- Проверяем, существует ли PaperDollFrame
    if PaperDollFrame then
        -- Очищаем текущие привязки
        PaperDollFrame:ClearAllPoints()
        
        -- Устанавливаем новые привязки с отступами по 32 пикселя
        PaperDollFrame:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", offsetX, -offsetY+2) -- Отступ слева и сверху
        PaperDollFrame:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -offsetX, -offsetY+2) -- Отступ справа и снизу
    end

    -- Проверяем, существует ли CharacterHeadSlot
    if CharacterHeadSlot then
        -- Очищаем текущую привязку
        CharacterHeadSlot:ClearAllPoints()
        
        -- Устанавливаем новую привязку со смещением вправо на 32 пикселя
        CharacterHeadSlot:SetPoint("TOPLEFT", CharacterFrameInset, "TOPLEFT", offsetX+4, -offsetY) -- Смещение вправо на 32 пикселя
    end

    -- Проверяем, существует ли CharacterHandsSlot
    if CharacterHandsSlot then
        -- Очищаем текущую привязку
        CharacterHandsSlot:ClearAllPoints()
        
        -- Устанавливаем новую привязку со смещением вправо на 32 пикселя
        CharacterHandsSlot:SetPoint("TOPRIGHT", CharacterFrameInset, "TOPRIGHT", -4 + offsetX, -offsetY) -- Смещение вправо на 32 пикселя
    end

    if PaperDollInnerBorderTopLeft then
        PaperDollInnerBorderTopLeft:ClearAllPoints()
        PaperDollInnerBorderTopLeft:SetPoint("TOPLEFT", CharacterHeadSlot, "TOPRIGHT", 5, 0) -- Поднимаем на 32 
    end

    if PaperDollInnerBorderTopRight then
        PaperDollInnerBorderTopRight:ClearAllPoints()
        PaperDollInnerBorderTopRight:SetPoint("TOPRIGHT", CharacterHandsSlot, "TOPLEFT", -6, 0) -- Поднимаем на 32 
    end

    if PaperDollInnerBorderBottomLeft then
        PaperDollInnerBorderBottomLeft:ClearAllPoints()
        PaperDollInnerBorderBottomLeft:SetPoint("BOTTOMLEFT", CharacterWristSlot, "BOTTOMRIGHT", 5, 0) -- Поднимаем на 32 
    end

    if PaperDollInnerBorderBottomRight then
        PaperDollInnerBorderBottomRight:ClearAllPoints()
        PaperDollInnerBorderBottomRight:SetPoint("BOTTOMRIGHT", CharacterTrinket1Slot, "BOTTOMLEFT", -6, 0) -- Поднимаем на 32 
    end

    -- Проверяем, существует ли CharacterMainHandSlot
    if CharacterMainHandSlot then
        -- Очищаем текущие привязки
        CharacterMainHandSlot:ClearAllPoints()
        
        -- Устанавливаем новую привязку, поднимая на 32 пикселя
        CharacterMainHandSlot:SetPoint("RIGHT", PaperDollInnerBorderBottom, "CENTER", -8, 0) -- Поднимаем на 32 пикселя
    end

    -- Проверяем, существует ли CharacterStatsPane
    if CharacterStatsPane then
        -- Очищаем текущие привязки
        CharacterStatsPane:ClearAllPoints()
        
        -- Устанавливаем новые привязки со смещением вправо на 32 пикселя
        CharacterStatsPane:SetPoint("TOPLEFT", CharacterFrameInsetRight, "TOPLEFT", 3, -3 - offsetY) -- Смещаем верхний левый якорь вправо на 32 пикселя
        CharacterStatsPane:SetPoint("BOTTOMRIGHT", CharacterFrameInsetRight, "BOTTOMRIGHT", -3, 2 - offsetY) -- Смещаем нижний правый якорь вправо на 32 пикселя
    end

    -- Проверяем, существует ли PaperDollFrame.TitleManagerPane.ScrollBox
    if PaperDollFrame.TitleManagerPane.ScrollBox then
        
        --PaperDollFrame.TitleManagerPane.ScrollBox:SetWidth(172 + offsetX - 6)
        PaperDollFrame.TitleManagerPane.ScrollBox:SetHeight(354 - offsetY + 4)
        
        -- Очищаем текущие привязки
        PaperDollFrame.TitleManagerPane.ScrollBox:ClearAllPoints()
        
        -- Устанавливаем новые привязки с добавлением смещения
        PaperDollFrame.TitleManagerPane.ScrollBox:SetPoint("TOPLEFT", CharacterFrameInsetRight, "TOPLEFT", 4 + offsetX + 4, - offsetY)
    end

    -- Проверяем, существует ли PaperDollFrame.TitleManagerPane.ScrollBox
    if PaperDollFrame.EquipmentManagerPane then
        
        PaperDollFrame.EquipmentManagerPane:SetHeight(354 - offsetY + 4)
        
        -- Очищаем текущие привязки
        PaperDollFrame.EquipmentManagerPane:ClearAllPoints()
        
        -- Устанавливаем новые привязки с добавлением смещения
        PaperDollFrame.EquipmentManagerPane:SetPoint("TOPLEFT", CharacterFrameInsetRight, "TOPLEFT", 4 + offsetX + 8, - offsetY)
        
        PaperDollFrame.EquipmentManagerPane.ScrollBox:SetHeight(330)
        
        -- Очищаем текущие привязки
        PaperDollFrame.EquipmentManagerPane.ScrollBox:ClearAllPoints()
        
        -- Устанавливаем новые привязки с добавлением смещения
        PaperDollFrame.EquipmentManagerPane.ScrollBox:SetPoint("TOPLEFT", CharacterFrameInsetRight, "TOPLEFT", offsetX + 10, - offsetY-40)
    end

    -- Проверяем, существует ли CharacterFrameTitleText
    if CharacterFrameTitleText then
        -- Устанавливаем новый размер шрифта и выравнивание
        CharacterFrameTitleText:SetFont(CharacterFrameTitleText:GetFont(), 20) -- Меняем размер шрифта на 20
        CharacterFrameTitleText:SetJustifyH("LEFT") -- Выравниваем по левому краю
    end

    if CharacterLevelText then
        CharacterLevelText:SetJustifyH("LEFT") -- Выравниваем по левому краю
        CharacterLevelText:ClearAllPoints()
        
        -- Устанавливаем новые привязки с отступом слева 24 пикселя и теми же значениями для других параметров
        CharacterLevelText:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", offsetX + 4, -22-offsetY)
        CharacterLevelText:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -24, -22-offsetY)
    end

    -- Проверяем, существует ли CharacterFrameTitleText
    if CharacterFrameTitleText then
        -- Очищаем все привязки
        CharacterFrameTitleText:ClearAllPoints()
        
        -- Устанавливаем новые привязки с отступом слева 24 пикселя и теми же значениями для других параметров
        CharacterFrameTitleText:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", offsetX + 4, -offsetY-4)
        CharacterFrameTitleText:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -offsetX, -offsetY-4)
    end
end

-- Скрытие ненужных фреймов, регионов и текстур
local function hideFramesAndRegions()
    local elementsToHide = {
        CharacterStatsPane.ClassBackground,
        PaperDollSidebarTabs.DecorLeft,
        PaperDollSidebarTabs.DecorRight,
        PaperDollInnerBorderBottom2,
        CharacterStatsPane.ItemLevelCategory.Background,
        CharacterStatsPane.AttributesCategory.Background,
        CharacterStatsPane.EnhancementsCategory.Background,
        
        PaperDollSidebarTab1,
        PaperDollSidebarTab2,
        PaperDollSidebarTab3,
        
        CharacterFinger0SlotFrame,
        CharacterFinger1SlotFrame,
        CharacterTrinket0SlotFrame,
        CharacterTrinket1SlotFrame,
        CharacterLegsSlotFrame,
        CharacterFeetSlotFrame,
        CharacterWaistSlotFrame,
        CharacterHandsSlotFrame,
        CharacterWristSlotFrame,
        CharacterTabardSlotFrame,
        CharacterShirtSlotFrame,
        CharacterChestSlotFrame,
        CharacterBackSlotFrame,
        CharacterShoulderSlotFrame,
        CharacterNeckSlotFrame,
        CharacterHeadSlotFrame,
        CharacterMainHandSlotFrame,
        CharacterSecondaryHandSlotFrame,
    }

    -- Скрываем все элементы из списка
    for _, element in ipairs(elementsToHide) do
        if element then
            element:Hide()
            element:SetAlpha(0)
        end
    end

    -- Функция для скрытия первого региона
    local function HideRegion(frame)
        local regions = {frame:GetRegions()}
        if #regions > 0 and regions[17] then
            regions[17]:Hide()
        end
    end

    if CharacterMainHandSlot then
        -- Скрываем все регионы, которые не являются фреймами, в CharacterMainHandSlotFrame
        HideRegion(CharacterMainHandSlot)
    end

    if CharacterSecondaryHandSlot then
        -- Скрываем все регионы, которые не являются фреймами, в CharacterMainHandSlotFrame
        HideRegion(CharacterSecondaryHandSlot)
    end

    -- Функция для скрытия конкретных регионов
    local function HideSpecificRegions(frames)
        -- Получаем все регионы, связанные с фреймом
        for _, child in ipairs(frames) do
            if child.BgBottom then
                child.BgBottom:Hide()
            end
            
            if child.BgMiddle then
                
                child.BgMiddle:Hide()
            end
            
            if child.BgTop then
                child.BgTop:Hide()
            end
            
            if child.Stripe then
                child.Stripe:Hide()
            end
        end
    end

    PaperDollFrame.TitleManagerPane.ScrollBox.ScrollTarget:HookScript("OnUpdate", function()
            HideSpecificRegions({PaperDollFrame.TitleManagerPane.ScrollBox.ScrollTarget:GetChildren()})  
    end)

    PaperDollFrame.EquipmentManagerPane.ScrollBox.ScrollTarget:HookScript("OnUpdate", function()
            HideSpecificRegions({PaperDollFrame.EquipmentManagerPane.ScrollBox.ScrollTarget:GetChildren()})  
    end)
end

-- Обновление текстур фрейсов и регионов
local function updateTextures()
    function ApplyMaskToTexture(texture)
        -- Проверка, существует ли уже маска
        if not texture.mask then
            -- Создаем маску
            local mask = texture:GetParent():CreateMaskTexture()
            
            -- Устанавливаем текстуру маски
            mask:SetTexture("Interface\\AddOns\\ConsoleMenu\\Assets\\Mask")
            mask:SetAllPoints(texture)  -- Маска будет размером с текстуру
            
            -- Применяем маску
            texture:AddMaskTexture(mask)
            
            -- Сохраняем ссылку на маску, чтобы избежать повторного создания
            texture.mask = mask
        end
    end

    function SetAllPointsParent(frame)
        local parent = frame:GetParent()
        if frame and parent then
            frame:ClearAllPoints()
            frame:SetAllPoints(parent)
        end
    end

    function UpdatePaperDollSidebarTab(frame)
        frame:SetWidth(sizePaperDollTabs)
        frame:SetHeight(sizePaperDollTabs)
        
        frame.Icon:ClearAllPoints()
        frame.Icon:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame.Icon:SetWidth(sizePaperDollTabs-14)
        frame.Icon:SetHeight(sizePaperDollTabs-14)
        
        frame.TabBg:ClearAllPoints()
        frame.TabBg:SetAllPoints(frame)
        
        frame.Highlight:ClearAllPoints()
        frame.Highlight:SetAllPoints(frame)
        
        local atlasInfo = C_Texture.GetAtlasInfo("plunderstorm-actionbar-slot-border")
        if atlasInfo then
            -- Если текстура найдена в атласе, устанавливаем ее на фрейм
            frame.TabBg:SetTexture(atlasInfo.file)
            frame.TabBg:SetTexCoord(atlasInfo.leftTexCoord, atlasInfo.rightTexCoord, atlasInfo.topTexCoord, atlasInfo.bottomTexCoord)
        else
            -- Если текстура не найдена, выводим ошибку в лог
            print("Текстура не найдена")
        end
        
        atlasInfo = C_Texture.GetAtlasInfo("plunderstorm-actionbar-slot-border-swappable")
        if atlasInfo then
            -- Если текстура найдена в атласе, устанавливаем ее на фрейм
            frame.Highlight:SetTexture(atlasInfo.file)
            frame.Highlight:SetTexCoord(atlasInfo.leftTexCoord, atlasInfo.rightTexCoord, atlasInfo.topTexCoord, atlasInfo.bottomTexCoord)
        else
            -- Если текстура не найдена, выводим ошибку в лог
            print("Текстура не найдена")
        end
        
    end

    if PaperDollSidebarTab1 then
        PaperDollSidebarTab1:HookScript("OnUpdate", function()
                UpdatePaperDollSidebarTab(PaperDollSidebarTab1)
                
        end)
        
        ApplyMaskToTexture(PaperDollSidebarTab1.Icon)
    end

    if PaperDollSidebarTab2 then
        PaperDollSidebarTab2:HookScript("OnUpdate", function()
                UpdatePaperDollSidebarTab(PaperDollSidebarTab2)
        end)
        
        PaperDollSidebarTab2.Icon:SetTexture("Interface\\Icons\\UI_Profession_Inscription")
        PaperDollSidebarTab2.Icon:SetTexCoord(0, 1, 0, 1)
        
        
        ApplyMaskToTexture(PaperDollSidebarTab2.Icon)
        
    end

    if PaperDollSidebarTab3 then
        PaperDollSidebarTab3:HookScript("OnUpdate", function()
                
                PaperDollSidebarTab3.Icon:SetTexture("Interface\\Icons\\Trade_Archaeology_DruidPriestStatueSet")
                PaperDollSidebarTab3.Icon:SetTexCoord(0, 1, 0, 1)
                
                UpdatePaperDollSidebarTab(PaperDollSidebarTab3)
        end)
        
        
        ApplyMaskToTexture(PaperDollSidebarTab3.Icon)
        
    end

    local slotInfo = {
        {frame = "CharacterMainHandSlot", textureID = 136518, newTexture = "Interface\\Icons\\INV_Sword_111"},
        {frame = "CharacterSecondaryHandSlot", textureID = 136524, newTexture = "Interface\\Icons\\INV_Shield_09"},
        {frame = "CharacterHeadSlot", textureID = 136516, newTexture = "Interface\\Icons\\INV_Helmet_22"},
        {frame = "CharacterNeckSlot", textureID = 136519, newTexture = "Interface\\Icons\\INV_11_0_Arathor_Necklace_01_Color2"},
        {frame = "CharacterShoulderSlot", textureID = 136526, newTexture = "Interface\\Icons\\INV_Shoulder_29"},
        {frame = "CharacterBackSlot", textureID = 136512, newTexture = "Interface\\Icons\\INV_Misc_Cape_19"},
        {frame = "CharacterChestSlot", textureID = 136512, newTexture = "Interface\\Icons\\INV_Chest_Armor_Dwarf_D_01"},
        {frame = "CharacterShirtSlot", textureID = 136525, newTexture = "Interface\\Icons\\INV_Shirt_Basic_A_02_Dark"},
        {frame = "CharacterTabardSlot", textureID = 136527, newTexture = "Interface\\Icons\\INV_Tabard_Basic_B_01_grey"},
        {frame = "CharacterWristSlot", textureID = 136530, newTexture = "Interface\\Icons\\INV_Bracer_07"},
        {frame = "CharacterHandsSlot", textureID = 136515, newTexture = "Interface\\Icons\\INV_Misc_Desecrated_ClothGlove"},
        {frame = "CharacterWaistSlot", textureID = 136529, newTexture = "Interface\\Icons\\INV_Belt_04"},
        {frame = "CharacterLegsSlot", textureID = 136517, newTexture = "Interface\\Icons\\INV_Pants_06"},
        {frame = "CharacterFeetSlot", textureID = 136513, newTexture = "Interface\\Icons\\INV_Boots_07"},
        {frame = "CharacterFinger0Slot", textureID = 136514, newTexture = "Interface\\Icons\\INV_Jewelry_Ring_03"},
        {frame = "CharacterFinger1Slot", textureID = 136514, newTexture = "Interface\\Icons\\INV_Jewelry_Ring_03"},
        {frame = "CharacterTrinket0Slot", textureID = 136528, newTexture = "Interface\\Icons\\INV_6_2Raid_Trinket_4c"},
        {frame = "CharacterTrinket1Slot", textureID = 136528, newTexture = "Interface\\Icons\\INV_6_2Raid_Trinket_3b"}
    }

    for _, item in ipairs(slotInfo) do
        local frame = _G[item.frame]
        local icon = frame.icon
        local border = frame.NormalTexture
        
        frame:HookScript("OnUpdate", function()
                if icon:GetTexture() == item.textureID then
                    icon:SetTexture(item.newTexture)
                    icon:SetTexCoord(0, 1, 0, 1)
                    icon:SetDesaturated(true)
                end
        end)
        
        
        ApplyMaskToTexture(icon)
        -- Получаем информацию об атласе один раз
        border:ClearAllPoints()
        border:SetPoint("CENTER", frame, "CENTER", 0, 0)
        border:SetAtlas("plunderstorm-actionbar-slot-border", false)
        border:SetWidth(50)
        border:SetHeight(50)
    end
end

local function AddPaperDollTabsDropdown()
    
    local items;

    local function IsSelected(index) return index == g_selectedIndex; end

    local function SetSelected(index)
        g_selectedIndex = index;

        -- Применяем действия в зависимости от выбранного значения
        if index == 1 then
            PaperDollFrame_SetSidebar(PaperDollFrame, 1)
        elseif index == 2 then
            PaperDollFrame_SetSidebar(PaperDollFrame, 3)
        elseif index == 3 then
            PaperDollFrame_SetSidebar(PaperDollFrame, 2)
        end

        -- Обновление текста дропдауна
        if dropdown then
            dropdown:Hide()  -- Закрываем дропдаун
            dropdown:Show()  -- Открываем дропдаун
        end
    end

    function SelectDropdownValueFromOutside(index)
        if index >= 1 and index <= #items then  -- Проверяем, чтобы индекс был в пределах допустимого диапазона
            SetSelected(index)
        else
            print("Неверный индекс")
        end
    end

    local function GeneratorFunction(dropdown, rootDescription)
        items = {PAPERDOLL_SIDEBAR_STATS, PAPERDOLL_EQUIPMENTMANAGER, PAPERDOLL_SIDEBAR_TITLES}

        for index, name in ipairs(items) do
            rootDescription:CreateRadio(name, IsSelected, SetSelected, index);
        end
    end

    -- Создание дропдауна и сохранение глобальной ссылки
    dropdown = CreateFrame("DropdownButton", nil, PaperDollFrame, "WowStyle1DropdownTemplate");
    dropdown:SetWidth(180);
    dropdown:SetDefaultText("Окно персонажа");
    dropdown:SetPoint("TOPRIGHT", PaperDollFrame, "TOPRIGHT", 0, 0);
    dropdown:SetupMenu(GeneratorFunction);
end

-- Отображение экипировки с указанной характеристикой
local function ShowSearchOverlayForMissingStat(stat)
    for slotID = 1, 19 do  -- Перебираем все слоты персонажа
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink then
            -- TODO: Добавить получение характеристик камней и чар 
            local stats = C_Item.GetItemStats(itemLink)
            local hasStat = stats and stats[stat] ~= nil
            
            -- Если характеристика отсутствует, показать overlay
            if not hasStat then
                slotsIDs[slotID].searchOverlay:Show()
            else
                slotsIDs[slotID].searchOverlay:Hide()
            end
        end
    end
end

-- Скрытие затемнений экипировки
local function HideSearchOverlayForMissingStat()
    for slotID = 1, 19 do  -- Перебираем все слоты персонажа
        if slotsIDs[slotID] and slotsIDs[slotID].searchOverlay then
            slotsIDs[slotID].searchOverlay:Hide()
        end
    end
end

-- Функция для отображения тултипа на строке характеристики
local function ShowTooltipOnCurrentStat()
    -- TODO: Добавить визуальный маркер фокуса
    local targetLabel = statItems[currentStatIndex]
    currentFrame = nil  -- Очистим currentFrame, если фрейм не найден

    -- Проверяем наличие CharacterStatsPane
    if not CharacterStatsPane then
        print("CharacterStatsPane не найден.")
        return
    end

    -- Перебираем всех детей CharacterStatsPane
    for _, child in ipairs({CharacterStatsPane:GetChildren()}) do
        -- Проверяем, имеет ли child поле Label и метод GetText для Label
        if child.Label and child.Label.GetText then
            local labelText = child.Label:GetText()
            if labelText == targetLabel then
                currentFrame = child  -- Устанавливаем найденный фрейм в currentFrame
                break  -- Останавливаем поиск, так как фрейм найден
            end
        end
    end

    if currentFrame and currentFrame:IsVisible() then
        GameTooltip:SetOwner(currentFrame, "ANCHOR_RIGHT")
        if currentFrame.tooltip then
            GameTooltip:SetText(currentFrame.tooltip)
            if currentFrame.tooltip2 then
                GameTooltip:AddLine(currentFrame.tooltip2)
            end
        else
            
        end
        GameTooltip:Show()
    end

    if showSlotsWithStat and currentFrame then
        local labelText = currentFrame.Label:GetText()

        -- TODO: Добавить остальные отображаемые характеристики 
        if labelText == PRIMARY_STAT2_TOOLTIP_NAME..":" then ShowSearchOverlayForMissingStat("ITEM_MOD_AGILITY_SHORT")
        elseif labelText == PRIMARY_STAT3_TOOLTIP_NAME..":" then ShowSearchOverlayForMissingStat("ITEM_MOD_STAMINA_SHORT")
        elseif labelText == PRIMARY_STAT4_TOOLTIP_NAME..":" then ShowSearchOverlayForMissingStat("ITEM_MOD_INTELLECT_SHORT")
        elseif labelText == STAT_MASTERY..":" then ShowSearchOverlayForMissingStat("ITEM_MOD_MASTERY_RATING_SHORT")
        elseif labelText == STAT_CRITICAL_STRIKE..":" then ShowSearchOverlayForMissingStat("ITEM_MOD_CRIT_RATING_SHORT")
        elseif labelText == STAT_HASTE..":" then ShowSearchOverlayForMissingStat("ITEM_MOD_HASTE_RATING_SHORT")
        elseif labelText == STAT_VERSATILITY..":" then ShowSearchOverlayForMissingStat("ITEM_MOD_VERSATILITY")
        elseif labelText == STAT_AVOIDANCE..":" then ShowSearchOverlayForMissingStat("ITEM_MOD_CR_AVOIDANCE_SHORT")
        elseif labelText == STAT_ARMOR..":" then ShowSearchOverlayForMissingStat("RESISTANCE0_NAME")
        end
    end

end

-- Включение / выключение функции затемнения слотов, предметы в которых не имеют выбранную характеристику
local function ToggleSearchOverlayForMissingStat()
    showSlotsWithStat = not showSlotsWithStat

    if showSlotsWithStat then
        ShowTooltipOnCurrentStat()
    else
        HideSearchOverlayForMissingStat()
    end
end

-- Функция для отображения подсказки на текущем слоте и скрытия выделения у других
local function ShowTooltipOnCurrentSlot()
    -- Перебираем все слоты и скрываем подсветку
    for i, slot in ipairs(inventorySlots) do
        if i == currentSlotIndex then
            -- Показываем выделение только для текущего слота
            --slot.AugmentBorderAnimTexture:Show()
            slot:LockHighlight()
        else
            -- Скрываем выделение для всех остальных слотов
            --slot.AugmentBorderAnimTexture:Hide()
            slot:UnlockHighlight()
        end
    end

    -- Отображаем подсказку на текущем слоте
    local currentSlot = inventorySlots[currentSlotIndex]
    if currentSlot and currentSlot:IsVisible() then
        GameTooltip:SetOwner(currentSlot, "ANCHOR_RIGHT")
        GameTooltip:SetInventoryItem("player", currentSlot:GetID())
        GameTooltip:Show()
    end
end

-- Обработка нажатий кнопок D-pad для перемещения между характеристиками
local function CharacterStatPaneOnDPadButtonPress(direction)
    if direction == "UP" then
        if currentStatIndex == nil then currentStatIndex = 1 else
            currentStatIndex = currentStatIndex - 1
            if currentStatIndex < 1 then
                currentStatIndex = #statItems
            end 
        end
        ShowTooltipOnCurrentStat()
    elseif direction == "DOWN" then
        if currentStatIndex == nil then currentStatIndex = 1 else
            currentStatIndex = currentStatIndex + 1
            if currentStatIndex > #statItems then
                currentStatIndex = 1
            end
        end
        ShowTooltipOnCurrentStat()
    elseif direction == "LEFT" then 
        paperDollSidebarFocus = false
        ShowTooltipOnCurrentSlot()
    end
end

-- Снять предмет экипировки
local function UnequipItemInCurrentSlot()
    if currentSlotIndex then
        if ( UnitAffectingCombat("player") and not INVSLOTS_EQUIPABLE_IN_COMBAT[slot:GetID()] ) then
            UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0);
            return;
        end
        local slot = inventorySlots[currentSlotIndex]
        local action = EquipmentManager_UnequipItemInSlot(slot:GetID())
        if action then
            EquipmentManager_RunAction(action)
        end
    end
end

-- Функция для скрытия PopoutButton кнопок у всех слотов
local function HideSlotsPopoutButton()
    for i, slot in ipairs(inventorySlots) do
        slot.popoutButton:Hide()
    end
end

-- Функция для отображения PopoutButton кнопок у всех слотов
local function ShowSlotsPopoutButton()
    for i, slot in ipairs(inventorySlots) do
        slot.popoutButton:Show()
    end
end

-- Скрытие highlight у всех слотов экипировки
local function HideAnySlotHighlight()
    for i, slot in ipairs(inventorySlots) do
        slot:UnlockHighlight()
    end
end

-- Обработка нажатий кнопок D-pad
local function PaperDollItemsOnDPadButtonPress(direction)
    if direction == "UP" then
        if currentSlotIndex == nil then currentSlotIndex = 1 else
            currentSlotIndex = currentSlotIndex - 1
            if currentSlotIndex < 1 then
                currentSlotIndex = #inventorySlots
            end
        end

        if EquipmentFlyoutFrame:IsVisible() then
            EquipmentFlyout_Hide()
            currentEquipmentFlyoutIndex = nil
        end

        ShowTooltipOnCurrentSlot()

    elseif direction == "DOWN" then
        if currentSlotIndex == nil then currentSlotIndex = 1 else
            currentSlotIndex = currentSlotIndex + 1
            if currentSlotIndex > #inventorySlots then
                currentSlotIndex = 1
            end
        end

        if EquipmentFlyoutFrame:IsVisible() then
            EquipmentFlyout_Hide()
            currentEquipmentFlyoutIndex = nil
        end

        ShowTooltipOnCurrentSlot()

    elseif direction == "RIGHT" then
        if currentSlotIndex == nil then currentSlotIndex = 1 end
        if currentSlotIndex > 0 and currentSlotIndex < 8 then
            currentSlotIndex = currentSlotIndex + 10
            ShowTooltipOnCurrentSlot()
        elseif currentSlotIndex == 8 or currentSlotIndex == 9 then
            currentSlotIndex = currentSlotIndex + 1
            ShowTooltipOnCurrentSlot()
        elseif currentSlotIndex == 10 then
            currentSlotIndex = 18
            ShowTooltipOnCurrentSlot()
        elseif currentSlotIndex > 10 and currentSlotIndex <= 18 then
            inventorySlots[currentSlotIndex]:UnlockHighlight()
            GameTooltip:Hide()
            paperDollSidebarFocus = true
            if currentStatIndex then
                ShowTooltipOnCurrentStat()
            end
        end
    elseif direction == "LEFT" then
        if currentSlotIndex == nil then currentSlotIndex = 1 end
        if (currentSlotIndex < 18 and currentSlotIndex > 10) then
            currentSlotIndex = currentSlotIndex- 10
        elseif currentSlotIndex == 10 or currentSlotIndex == 9 then
            currentSlotIndex = currentSlotIndex - 1
        elseif currentSlotIndex == 18 then
            currentSlotIndex = 10
        end

        ShowTooltipOnCurrentSlot()
    end
end

-- Показать / скрыть EquipmentFlyoutFrame
local function ToggleEquipmentFlyoutFrame()
    if currentSlotIndex then
        currentEquipmentFlyoutIndex = nil
        local slot = inventorySlots[currentSlotIndex]
        local availableItems = {}
        local itemCount = 0
        GetInventoryItemsForSlot(slot:GetID(), availableItems)

        -- Подсчёт количества элементов в availableItems
        for _ in pairs(availableItems) do
            itemCount = itemCount + 1
        end

        if not EquipmentFlyoutFrame:IsVisible() and itemCount > 0 then
            EquipmentFlyoutPopoutButton_OnClick(slot.popoutButton)
            GameTooltip:Hide()
        else
            EquipmentFlyout_Hide()
            ShowTooltipOnCurrentSlot()
        end
    end
end

-- Фунукнция для отображения подсказке на текущем слоте (кнопке) EquipmentFlyoutFrame
local function HideAnyEquipementFlyoutButtonHighlight(direction)
    -- Перебираем все слоты и скрываем подсветку
    for i, button in ipairs(EquipmentFlyoutFrame.buttons) do
        button:UnlockHighlight()
    end
    currentEquipmentFlyoutIndex = nil
end

local function ShowTooltipOnCurrentEquipementFlyoutButton(direction)
    -- Перебираем все слоты и скрываем подсветку
    for i, button in ipairs(EquipmentFlyoutFrame.buttons) do
        if i == currentEquipmentFlyoutIndex then
            -- Показываем выделение только для текущего слота
            button:LockHighlight()
            local onEnterFunc = button:GetScript("OnEnter");
			if ( onEnterFunc ) then
				onEnterFunc(button);
			end
        else
            -- Скрываем выделение для всех остальных слотов
            button:UnlockHighlight()
        end
    end
end

-- Фунукнция для нажатия на текущую кнопку EquipmentFlyoutFrame
local function CurrentEquipementFlyoutButtonOnClick()
    if currentEquipmentFlyoutIndex then
        -- Перебираем все слоты и скрываем подсветку
        for i, button in ipairs(EquipmentFlyoutFrame.buttons) do
            if i == currentEquipmentFlyoutIndex then
                -- Показываем выделение только для текущего слота
                local onClick = button:GetScript("OnClick");
                if ( onClick ) then
                    onClick(button);
                end
            end
        end
        HideAnyEquipementFlyoutButtonHighlight()
    end
end

-- Обработка нажатий кнопок D-pad для перемещения наборами экипировки
local function EquipmentFlyoutOnDPadButtonPress(direction)
    local buttonsNum = EquipmentFlyoutFrame.totalItems
    if direction == "RIGHT" then
        if currentEquipmentFlyoutIndex == nil then currentEquipmentFlyoutIndex = 1 
        elseif currentEquipmentFlyoutIndex > 0 and currentEquipmentFlyoutIndex < buttonsNum then
            currentEquipmentFlyoutIndex = currentEquipmentFlyoutIndex + 1
        elseif currentEquipmentFlyoutIndex == buttonsNum and buttonsNum > 1 then
            currentEquipmentFlyoutIndex = 1
        end
        
    elseif direction == "LEFT" then
        if currentEquipmentFlyoutIndex == nil then currentEquipmentFlyoutIndex = 1
        elseif (currentEquipmentFlyoutIndex <= buttonsNum and currentEquipmentFlyoutIndex > 1) then
            currentEquipmentFlyoutIndex = currentEquipmentFlyoutIndex - 1
        elseif currentEquipmentFlyoutIndex == 1 and buttonsNum > 1  then
            currentEquipmentFlyoutIndex = buttonsNum
        end
    end

    ShowTooltipOnCurrentEquipementFlyoutButton()
end

-- Обработка нажатий кнопок D-pad для перемещения наборами экипировки
local function EquipmentManagerPaneOnDPadButtonPress(direction)
end

-- Обработка нажатий кнопок D-pad для перемещения между характеристиками
local function TitleManagerPaneOnDPadButtonPress(direction)

    local titlePane = PaperDollFrame.TitleManagerPane
    local titleItems = titlePane.titles

    -- Обновление индекса текущего звания на основе направления
    if direction == "UP" then
        currentTitleIndex = currentTitleIndex - 1
        if currentTitleIndex < 1 then
            currentTitleIndex = #titleItems  -- Переход к последнему элементу
        end 
    elseif direction == "DOWN" then
        currentTitleIndex = currentTitleIndex + 1
        if currentTitleIndex > #titleItems then
            currentTitleIndex = 1  -- Переход к первому элементу
        end
    end

    -- Прокрутка к элементу в ScrollBox
    titlePane.ScrollBox:ScrollToElementDataIndex(currentTitleIndex)

    -- Получение фрейма элемента, на который нужно "навести курсор"
    local targetTitleId = titleItems[currentTitleIndex].id

    for i, frame in ipairs({titlePane.ScrollBox.ScrollTarget:GetChildren()}) do
        if frame.titleId == targetTitleId then
            frame:LockHighlight()
        else
            frame:UnlockHighlight()
        end
    end
end

-- Применение звания
local function SetCurrentTitle()
    local titlePane = PaperDollFrame.TitleManagerPane
    local titleItems = titlePane.titles

    PaperDollFrame.TitleManagerPane.selected = currentId
    SetTitleByName(titleItems[currentTitleIndex].name)
    PaperDollTitlesPane_UpdateScrollBox()
end

-- Служебная функция для скрытия специфичных фреймов для вкладки PaperRollFrame
local function HideSpecificPaperDollTabsFrames()
    GameTooltip:Hide()
    HideSearchOverlayForMissingStat()
    HideAnySlotHighlight()
end

-- Подключение контроллера
local function toggleController()
    -- Создаем фрейм для обработки событий геймпада
    local controllerHandler = CreateFrame("Frame", "ControllerHandler", PaperDollFrame)
    PaperDollFrame.ControllerHandler = controllerHandler

    PaperDollFrame:HookScript("OnShow", function()
        SelectDropdownValueFromOutside(g_selectedIndex)
    end)

    PaperDollFrame:HookScript("OnHide", function()
        HideSpecificPaperDollTabsFrames()
        g_selectedIndex = 1
        currentSlotIndex = nil
        currentTitleIndex = 1
        currentStatIndex = nil
    end)

    -- Обработка нажатия кнопок геймпада
    function controllerHandler:OnGamePadButtonDown(button)
        -- Настройка кнопок в PaperDollFrame
        if button == "PADRSHOULDER" then
            -- Если индекс больше 3, сбрасываем его на 1
            if g_selectedIndex == 3 then
                g_selectedIndex = 1
            else
                g_selectedIndex = g_selectedIndex + 1
            end
            HideSpecificPaperDollTabsFrames()
            SelectDropdownValueFromOutside(g_selectedIndex)
        elseif button == "PADLSHOULDER" then
            -- Если индекс больше 3, уменьшаем его на 1
            if g_selectedIndex > 1 then
                g_selectedIndex = g_selectedIndex - 1
            else
                g_selectedIndex = 3
            end
            HideSpecificPaperDollTabsFrames()
            SelectDropdownValueFromOutside(g_selectedIndex)
        end

        if g_selectedIndex == 1 then
            if not paperDollSidebarFocus then
                -- Когда фокус на PaperDollItemsFrame
                if not EquipmentFlyoutFrame:IsVisible() then
                    -- Настройка для EquipmentManagerPane, когда EquipmentFlyoutFrame не отображается
                    if button == "PADDUP" then PaperDollItemsOnDPadButtonPress("UP")
                    elseif button == "PADDDOWN" then PaperDollItemsOnDPadButtonPress("DOWN")
                    elseif button == "PADDRIGHT" then PaperDollItemsOnDPadButtonPress("RIGHT")
                    elseif button == "PADDLEFT" then PaperDollItemsOnDPadButtonPress("LEFT")
                    elseif button == "PAD3" then ToggleEquipmentFlyoutFrame()
                    elseif button == "PAD4" then UnequipItemInCurrentSlot()
                    end
                else
                    -- Настройка для EquipmentManagerPane, когда EquipmentFlyoutFrame отображается
                    if button == "PADDUP" then PaperDollItemsOnDPadButtonPress("UP")
                    elseif button == "PADDDOWN" then PaperDollItemsOnDPadButtonPress("DOWN")
                    elseif button == "PADDRIGHT" then EquipmentFlyoutOnDPadButtonPress("RIGHT")
                    elseif button == "PADDLEFT" then EquipmentFlyoutOnDPadButtonPress("LEFT")
                    elseif button == "PAD3" then ToggleEquipmentFlyoutFrame()
                    elseif button == "PAD1" then CurrentEquipementFlyoutButtonOnClick()
                    elseif button == "PAD4" then UnequipItemInCurrentSlot()
                    end
                end
            else
                -- Когда фокус на CharacterStatsPane
                if button == "PADDUP" then CharacterStatPaneOnDPadButtonPress("UP")
                elseif button == "PADDDOWN" then CharacterStatPaneOnDPadButtonPress("DOWN")
                elseif button == "PADDLEFT" then CharacterStatPaneOnDPadButtonPress("LEFT")
                elseif button == "PAD3" then ToggleSearchOverlayForMissingStat()
                end
            end
        
        elseif g_selectedIndex == 2 then
            if not paperDollSidebarFocus then
                -- Когда фокус на PaperDollItemsFrame
                if not EquipmentFlyoutFrame:IsVisible() then
                    -- Настройка для EquipmentManagerPane, когда EquipmentFlyoutFrame не отображается
                    if button == "PADDUP" then PaperDollItemsOnDPadButtonPress("UP")
                    elseif button == "PADDDOWN" then PaperDollItemsOnDPadButtonPress("DOWN")
                    elseif button == "PADDRIGHT" then PaperDollItemsOnDPadButtonPress("RIGHT")
                    elseif button == "PADDLEFT" then PaperDollItemsOnDPadButtonPress("LEFT")
                    elseif button == "PAD3" then ToggleEquipmentFlyoutFrame()
                    end
                else
                    -- Настройка для EquipmentManagerPane, когда EquipmentFlyoutFrame отображается
                    if button == "PADDUP" then PaperDollItemsOnDPadButtonPress("UP")
                    elseif button == "PADDDOWN" then PaperDollItemsOnDPadButtonPress("DOWN")
                    elseif button == "PAD3" then ToggleEquipmentFlyoutFrame()
                    end
                end
            else
                -- Когда фокус на EquipmentManagerPane
            end
        elseif g_selectedIndex == 3 then
            -- Настройка для TitleManagerPane
            if button == "PADDUP" then TitleManagerPaneOnDPadButtonPress("UP")
            elseif button == "PADDDOWN" then TitleManagerPaneOnDPadButtonPress("DOWN")
            elseif button == "PAD1" then SetCurrentTitle()
            end
        end
    end

end

-- Инициализация списка фреймов в statItems только с анонимными фреймами
local function InitializestatItems()
        -- Проверяем наличие CharacterStatsPane
        if not CharacterStatsPane then
            print("CharacterStatsPane не найден.")
            return
        end

        if #statItems > 0 then
            return
        end
    
        -- Перебираем всех детей CharacterStatsPane, кроме 1, 3 и 4
        for i, child in ipairs({CharacterStatsPane:GetChildren()}) do
            if i ~= 1 and i ~= 3 and i ~= 4 then
                -- Проверяем, имеет ли child поле Label и может ли Label получить текст
                if child.Label and child.Label.GetText then
                    local labelText = child.Label:GetText()
                    if labelText then
                        table.insert(statItems, labelText)  -- Добавляем текст в таблицу statItems
                    end
                end
            end
        end
end

-- Замена настроек EquipmentFlyoutFrame
local function ChangeFlyoutSettings()
    if C_GamePad and C_GamePad.GetAllDeviceIDs and #C_GamePad.GetAllDeviceIDs() > 0 then
        -- Скрываем кнопку "Переместить в сумку", т.к. это действие будет перемещено на кнопку
        PaperDollItemsFrame.flyoutSettings = {
            onClickFunc = PaperDollFrameItemFlyoutButton_OnClick,
            getItemsFunc = PaperDollFrameItemFlyout_GetItems,
            postGetItemsFunc = PostGetItems,
            hasPopouts = true,
            parent = PaperDollFrame,
            anchorX = 0,
            anchorY = 2,
            verticalAnchorX = 0,
            verticalAnchorY = 0,
        }
    else
        PaperDollItemsFrame.flyoutSettings = {
            onClickFunc = PaperDollFrameItemFlyoutButton_OnClick,
            getItemsFunc = PaperDollFrameItemFlyout_GetItems,
            postGetItemsFunc = PaperDollFrameItemFlyout_PostGetItems,
            hasPopouts = true,
            parent = PaperDollFrame,
            anchorX = 0,
            anchorY = 2,
            verticalAnchorX = 0,
            verticalAnchorY = 0,
        }
    end
end

-- Применение модификаций
function ConsoleMenu:SetPaperDollFrame()

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    toggleController()
    AddPaperDollTabsDropdown()
    ChangeFlyoutSettings()

    -- Отображение / скрытие PopoutButton слотов в зависмости от подключенности геймпада
    -- TODO: Добавить отображение / скрытие при подключении / отключении геймпада (события)
    PaperDollFrame.EquipmentManagerPane:HookScript("OnShow", function()
        if C_GamePad and C_GamePad.GetAllDeviceIDs and #C_GamePad.GetAllDeviceIDs() > 0 then
            HideSlotsPopoutButton()  
        end
    end)

    -- Отслеживание изменений CharacterStatsPane
    CharacterStatsPane:HookScript("OnShow", function()
        InitializestatItems()
    end)

    CharacterStatsPane:HookScript("OnUpdate", function()
        if g_selectedIndex == 1 and paperDollSidebarFocus then
            currentFrame = nil  -- Очистим currentFrame, если фрейм не найден
            -- Перебираем всех детей CharacterStatsPane
            for _, child in ipairs({CharacterStatsPane:GetChildren()}) do
                -- Проверяем, имеет ли child поле Label и метод GetText для Label
                if child.Label and child.Label.GetText then
                    local labelText = child.Label:GetText()
                    if labelText == STAT_MASTERY..":" and labelText == statItems[currentStatIndex] then
                        Mastery_OnEnter(child)                
                        break  -- Останавливаем поиск, так как фрейм найден
                    end
                end
            end
        end
    end)

end

function PostGetItems(itemSlotButton, itemDisplayTable, numItems)
	if (PaperDollFrame.EquipmentManagerPane:IsShown() and (PaperDollFrame.EquipmentManagerPane.selectedSetID or GearManagerPopupFrame:IsShown())) then
		if ( not itemSlotButton.ignored ) then
			tinsert(itemDisplayTable, 1, EQUIPMENTFLYOUT_IGNORESLOT_LOCATION);
		else
			tinsert(itemDisplayTable, 1, EQUIPMENTFLYOUT_UNIGNORESLOT_LOCATION);
		end
		numItems = numItems + 1;
	end
	return numItems;
end