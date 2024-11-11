-- CharacterFrame.lua

local ConsoleMenu = LibStub("AceAddon-3.0"):GetAddon("ConsoleMenu")

local offsetX = 40
local offsetY = 40
local scale = 1
local g_selectedIndex = 1
local statsItems = {}
local currentStatsIndex = nil
local currentSlotIndex = nil

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

function ConsoleMenu:SetPaperDollFrame()

    moveFrames()
    hideFramesAndRegions()
    updateTextures()
    toggleController()
    addDropdown()

    -- Отслеживание изменений CharacterStatsPane
    CharacterStatsPane:HookScript("OnShow", function()
        InitializeStatsItems()
    end)
    CharacterStatsPane:HookScript("OnUpdate", function()
        currentFrame = nil  -- Очистим currentFrame, если фрейм не найден
        -- Перебираем всех детей CharacterStatsPane
        for _, child in ipairs({CharacterStatsPane:GetChildren()}) do
            -- Проверяем, имеет ли child поле Label и метод GetText для Label
            if child.Label and child.Label.GetText then
                local labelText = child.Label:GetText()
                if labelText == "Искусность:" and labelText == statsItems[currentStatsIndex] then
                    Mastery_OnEnter(child)                
                    break  -- Останавливаем поиск, так как фрейм найден
                end
            end
        end
    end)

end

-- Перемещение и изменение тточек привязки фреймов
function moveFrames()

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

    -- Создаем хуки для отслеживания открытия окна персонажа, репутации и токенов
    hooksecurefunc("ToggleCharacter", function()
            if CharacterFrame:IsShown() then
                CharacterFrame:SetWidth(540 + offsetX*2)
                CharacterFrame:SetHeight(424 + offsetY*2-32)
            end
    end)

    -- Проверяем, существует ли CharacterFrameTab1
    if CharacterFrameTab1 then
        -- Очищаем текущие привязки
        CharacterFrameTab1:ClearAllPoints()
        
        -- Устанавливаем новую привязку с изменением смещения по X
        CharacterFrameTab1:SetPoint("TOPLEFT", CharacterFrame, "BOTTOMLEFT", offsetX, 2) -- Заменяем 11 на 32
    end

    -- Проверяем, существует ли ReputationFrame.ScrollBox
    if ReputationFrame and ReputationFrame.ScrollBox then
        -- Очищаем текущие привязки
        ReputationFrame.ScrollBox:ClearAllPoints()
        
        -- Устанавливаем новые привязки с добавлением отступов по 32 пикселя слева и справа
        ReputationFrame.ScrollBox:SetPoint("TOPLEFT", CharacterFrameInset, "TOPLEFT", -20 + offsetX, -12) -- Отступ слева на 32 пикселя
        ReputationFrame.ScrollBox:SetPoint("BOTTOMRIGHT", CharacterFrameInset, "BOTTOMRIGHT", -offsetX, 2) -- Отступ справа на 32 пикселя
    end

    -- Проверяем, существует ли ReputationFrame.filterDropdown
    if ReputationFrame.filterDropdown then
        -- Очищаем текущие привязки
        ReputationFrame.filterDropdown:ClearAllPoints()
        
        -- Устанавливаем новые привязки с использованием -offsetX
        ReputationFrame.filterDropdown:SetPoint("TOPRIGHT", ReputationFrame, "TOPRIGHT", -offsetX+10, -30)
    end

    if TokenFrame and TokenFrame.ScrollBox then
        -- Очищаем текущие привязки
        TokenFrame.ScrollBox:ClearAllPoints()
        
        -- Устанавливаем новые привязки с добавлением отступов по 32 пикселя слева и справа
        TokenFrame.ScrollBox:SetPoint("TOPLEFT", CharacterFrameInset, "TOPLEFT", -20 + offsetX, -12) -- Отступ слева на 32 пикселя
        TokenFrame.ScrollBox:SetPoint("BOTTOMRIGHT", CharacterFrameInset, "BOTTOMRIGHT", -offsetX, 2) -- Отступ справа на 32 пикселя
    end

    -- Проверяем, существуют ли TokenFrame.filterDropdown и TokenFrame.CurrencyTransferLogToggleButton
    if TokenFrame and TokenFrame.filterDropdown and TokenFrame.CurrencyTransferLogToggleButton then
        local filterDropdown = TokenFrame.filterDropdown
        local toggleButton = TokenFrame.CurrencyTransferLogToggleButton
        
        -- Очищаем все привязки кнопки
        toggleButton:ClearAllPoints()
        
        -- Устанавливаем привязку слева от filterDropdown с отступом 12 пикселей
        toggleButton:SetPoint("RIGHT", filterDropdown, "LEFT", -12, 0)
    end

    -- Проверяем, существует ли TokenFrame.filterDropdown
    if TokenFrame and TokenFrame.filterDropdown then
        local filterDropdown = TokenFrame.filterDropdown
        
        -- Очищаем текущую привязку
        filterDropdown:ClearAllPoints()
        
        -- Устанавливаем новую привязку с изменением xOffset
        filterDropdown:SetPoint("TOPRIGHT", TokenFrame, "TOPRIGHT", -offsetX+10, -30) 
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
function hideFramesAndRegions()
    local elementsToHide = {
        CharacterFrame.NineSlice,
        CharacterFramePortrait,
        CharacterFrameBg,
        CharacterFrameInset.Bg,
        CharacterFrameInset.NineSlice,
        CharacterFrameInsetRight.NineSlice,
        CharacterFrameInsetRight.Bg,
        CharacterFrame.Background,
        CharacterStatsPane.ClassBackground,
        PaperDollSidebarTabs.DecorLeft,
        PaperDollSidebarTabs.DecorRight,
        CharacterFrame.TopTileStreaks,
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
        local regions = {frame:GetRegions()}  -- Получаем все регионы
        if #regions > 0 and regions[17] then
            regions[17]:Hide()  -- Скрываем первый регион
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
function updateTextures()
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
        border:SetAtlas("plunderstorm-actionbar-slot-border", false)
        border:SetWidth(52)
        border:SetHeight(52)
    end
end

function addDropdown()
    
    local items;

    local function IsSelected(index) return index == g_selectedIndex; end

    local function SetSelected(index)
        g_selectedIndex = index;

        -- Применяем действия в зависимости от выбранного значения
        if index == 1 then
            PaperDollFrame_SetSidebar(PaperDollFrame, 1)
            HideTooltipOnCurrentSlot()
        elseif index == 2 then
            PaperDollFrame_SetSidebar(PaperDollFrame, 3)
            HideTooltipOnCurrentSlot()
        elseif index == 3 then
            PaperDollFrame_SetSidebar(PaperDollFrame, 2)
            HideTooltipOnCurrentSlot()
        elseif index == 4 then
            PaperDollFrame_SetSidebar(PaperDollFrame, 1)
            HideTooltipOnCurrentSlot()
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
        items = {"Экипировка", "Комплекты экипировки", "Звания"}

            -- Добавляем "Характеристики" только если подключен геймпад
        if #C_GamePad.GetAllDeviceIDs() > 1 then
            table.insert(items, 4, "Характеристики")  -- Вставляем на вторую позицию
        end

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

-- Подключение контроллера
function toggleController()
    -- Создаем фрейм для обработки событий геймпада
    local controllerHandler = CreateFrame("Frame", "ControllerHandlerFrame", CharacterFrame)

    CharacterFrame:HookScript("OnShow", function()
        -- Включаем обработку геймпада
        controllerHandler:EnableGamePadButton(true)

        -- Добавляем обработчик событий геймпада
        controllerHandler:SetScript("OnGamePadButtonDown", function(_, button)
            --print("Button pressed:", button)
            controllerHandler:OnGamePadButtonDown(button)
        end)
    end)

    CharacterFrame:HookScript("OnHide", function()
        -- Отключаем обработку геймпада
        controllerHandler:EnableGamePadButton(false)
        controllerHandler:SetScript("OnGamePadButtonDown", nil) -- Очищаем обработчик событий
        HideTooltipOnCurrentSlot()
        currentSlotIndex = nil
        currentStatsIndex = nil
    end)

    -- Обработка нажатия кнопок геймпада
    function controllerHandler:OnGamePadButtonDown(button)
        -- print("Inside OnGamePadButtonDown function:", button)
        -- Закрываем меню при нажатии на кнопку "Круг" (Circle)
        if button == "PAD2" then
            HideUIPanel(CharacterFrame)
        -- Переключаем вкладки Character Frame
        elseif button == "PADRTRIGGER" then
            if CharacterFrame.selectedTab == 1 then ToggleCharacter("ReputationFrame")
            elseif CharacterFrame.selectedTab == 2 then ToggleCharacter("TokenFrame")
            elseif CharacterFrame.selectedTab == 3 then ToggleCharacter("PaperDollFrame")
            end
            HideTooltipOnCurrentSlot()
        elseif button == "PADLTRIGGER" then
            if CharacterFrame.selectedTab == 1 then ToggleCharacter("TokenFrame")
            elseif CharacterFrame.selectedTab == 2 then ToggleCharacter("PaperDollFrame")
            elseif CharacterFrame.selectedTab == 3 then ToggleCharacter("ReputationFrame")
            end
            HideTooltipOnCurrentSlot()
        end

        if CharacterFrame.selectedTab == 1 then
            -- Настройка кнопок в PaperDollFrame
            if button == "PADRSHOULDER" then
                -- Если индекс больше 3, сбрасываем его на 1
                if g_selectedIndex == 4 then
                    g_selectedIndex = 1
                    SelectDropdownValueFromOutside(g_selectedIndex)
                else
                    g_selectedIndex = g_selectedIndex + 1
                    SelectDropdownValueFromOutside(g_selectedIndex)
                end

            elseif button == "PADLSHOULDER" then
                -- Если индекс больше 3, уменьшаем его на 1
                if g_selectedIndex > 1 then
                    g_selectedIndex = g_selectedIndex - 1
                else
                    g_selectedIndex = 4
                end
                SelectDropdownValueFromOutside(g_selectedIndex)
            end

            if g_selectedIndex == 1 then
                -- Настройка для PaperDollItems
                if button == "PADDUP" then PaperDollItemsOnDPadButtonPress("UP")
                elseif button == "PADDDOWN" then PaperDollItemsOnDPadButtonPress("DOWN")
                elseif button == "PADDRIGHT" then PaperDollItemsOnDPadButtonPress("RIGHT")
                elseif button == "PADDLEFT" then PaperDollItemsOnDPadButtonPress("LEFT")
                end

            elseif g_selectedIndex == 2 then
                -- Настройка для TitleManagerPane (PaperDollItems блокируется)
            elseif g_selectedIndex == 3 then
                -- Настройка для StatsPane
            elseif g_selectedIndex == 4 then
                if button == "PADDUP" then StatsItemsOnDPadButtonPress("UP")
                elseif button == "PADDDOWN" then StatsItemsOnDPadButtonPress("DOWN")
                end
            end

        elseif CharacterFrame.selectedTab == 2 then
            -- Настройка кнопок в ReputationFrame
        elseif CharacterFrame.selectedTab == 3 then
            -- Настройка кнопок в TokenFrame

        end
    end

end

-- Функция для отображения подсказки на текущем слоте и скрытия выделения у других
function ShowTooltipOnCurrentSlot()
    -- Перебираем все слоты и скрываем подсветку
    for i, slot in ipairs(inventorySlots) do
        if slot.AugmentBorderAnimTexture then
            if i == currentSlotIndex then
                -- Показываем выделение только для текущего слота
                slot.AugmentBorderAnimTexture:Show()
            else
                -- Скрываем выделение для всех остальных слотов
                slot.AugmentBorderAnimTexture:Hide()
            end
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

function HideTooltipOnCurrentSlot()
    -- Перебираем все слоты и скрываем подсветку
    for i, slot in ipairs(inventorySlots) do
        if slot.AugmentBorderAnimTexture then
            slot.AugmentBorderAnimTexture:Hide()
            GameTooltip:Hide()
        end
    end
end

-- Обработка нажатий кнопок D-pad
function PaperDollItemsOnDPadButtonPress(direction)
    if direction == "UP" then
        currentSlotIndex = currentSlotIndex - 1
        if currentSlotIndex < 1 then
            currentSlotIndex = #inventorySlots
        end
    elseif direction == "DOWN" then
        if currentSlotIndex == nil then currentSlotIndex = 1 else
            currentSlotIndex = currentSlotIndex + 1
            if currentSlotIndex > #inventorySlots then
                currentSlotIndex = 1
            end
        end
    elseif direction == "RIGHT" then
        if currentSlotIndex == nil then currentSlotIndex = 1 end
        if currentSlotIndex > 0 and currentSlotIndex < 8 then
            currentSlotIndex = currentSlotIndex + 10
        elseif currentSlotIndex == 8 or currentSlotIndex == 9 then
            currentSlotIndex = currentSlotIndex + 1
        elseif currentSlotIndex == 10 then
            currentSlotIndex = 18
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
    end

    -- Обновляем отображение подсказки
    ShowTooltipOnCurrentSlot()
end

-- Инициализация списка фреймов в statsItems только с анонимными фреймами
function InitializeStatsItems()
        -- Проверяем наличие CharacterStatsPane
        if not CharacterStatsPane then
            print("CharacterStatsPane не найден.")
            return
        end

        if #statsItems > 0 then
            return
        end
    
        -- Перебираем всех детей CharacterStatsPane, кроме 1, 3 и 4
        for i, child in ipairs({CharacterStatsPane:GetChildren()}) do
            if i ~= 1 and i ~= 3 and i ~= 4 then
                -- Проверяем, имеет ли child поле Label и может ли Label получить текст
                if child.Label and child.Label.GetText then
                    local labelText = child.Label:GetText()
                    if labelText then
                        table.insert(statsItems, labelText)  -- Добавляем текст в таблицу statsItems
                    end
                end
            end
        end
    
        -- Вывод для проверки
        for i, label in ipairs(statsItems) do
            print("Статистика #"..i..":", label)
        end
end


-- Функция для отображения тултипа на текущем анонимном фрейме
function ShowTooltipOnCurrentStat()
    local targetLabel = statsItems[currentStatsIndex]
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
end

-- Обработка нажатий кнопок D-pad для перемещения между анонимными фреймами в statsItems
function StatsItemsOnDPadButtonPress(direction)
    if direction == "UP" then
        if currentStatsIndex == nil then currentStatsIndex = 1 else
            currentStatsIndex = currentStatsIndex - 1
            if currentStatsIndex < 1 then
                currentStatsIndex = #statsItems
            end 
        end
    elseif direction == "DOWN" then
        if currentStatsIndex == nil then currentStatsIndex = 1 else
            currentStatsIndex = currentStatsIndex + 1
            if currentStatsIndex > #statsItems then
                currentStatsIndex = 1
            end
        end
    end

    -- Обновляем отображение тултипа для текущего фрейма
    ShowTooltipOnCurrentStat()
end
