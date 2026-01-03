-- FastTravelFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame

local frameWidth = 440
local viewedItemCount = 3
local sectionHeight = 52
local sectionPadding = 8
local iconSize = sectionHeight - sectionPadding * 2
local titleFontSize = 20
local tabFontSize = 18
local itemFontSize = 20

local animationDuration = 0.1

local className, classFile = UnitClass("player")

local focusedIndex = 1
local focusedTab = 1
local tabs = {}

local houseList = {}
local currentHouseInfo = nil

local softTargetEnemy
local gamePadActive = false

local mageSpells = {
    azeroth = {
        single = {446540, 395277, 281403, 281404, 224869, 193759, 132621, 132627, 88342, 88344, 53140, 32272, 3561, 3567, 3562, 3563, 3565, 3566, 49359, 49358},
        group = {446534, 395289, 281400, 281402, 224871, 193759, 132620, 132626, 88345, 88346, 53142, 32267, 10059, 11417, 11416, 11418, 11419, 11420, 49361, 49360}
    },
    world = {
        single = {344587, 176248, 176242, 35715, 33690},
        group = {344597, 176246, 176244, 33691, 35717}
    },
    actual = {
        single = {446540},
        group = {446534}
    }
}

local deathknightSpells = {
    50977,
}

local hearthstonesToys = {}

-- Функция для инициализации вкладок
local function InitTabs()
    local currentIndex = 1
    -- Создаем вкладки
    tabs[currentIndex] = { title = "Избранное"}
    currentIndex = currentIndex + 1

    local flyoutSpellID = 244
    _, _, numSlots, isKnown = GetFlyoutInfo(flyoutSpellID)

    if isKnown then
        tabs[currentIndex] = { title = "Путь героя", spells = {} }
        currentIndex = currentIndex + 1
        for i = 1, numSlots do
            local flyoutSpellID, _, isKnown, _, _ = GetFlyoutSlotInfo(flyoutSpellID, i)
            if flyoutSpellID and isKnown then
                table.insert(tabs[2].spells, flyoutSpellID)
            end
        end
    end 

    if classFile == "MAGE" then
        tabs[currentIndex] = { title = "Азерот", spells = {} }
        currentIndex = currentIndex + 1
        tabs[currentIndex] = { title = "Мир", spells = {} }
        currentIndex = currentIndex + 1
    end
end

-- Функция для телепорта домой или возврата из жилища
local function TeleportToHouse()
    if not C_Housing then
        return
    end
    
    local houseInfo = currentHouseInfo

    if not houseInfo then
        return
    end
    
    local teleportToPlot = true

    if C_HousingNeighborhood.CanReturnAfterVisitingHouse() then
        local currentNeighborhoodGUID = C_Housing.GetCurrentNeighborhoodGUID()
        if currentNeighborhoodGUID and houseInfo and currentNeighborhoodGUID == houseInfo.neighborhoodGUID then
            teleportToPlot = false
        end
    end
    
    if teleportToPlot then
        C_Housing.TeleportHome(houseInfo.neighborhoodGUID, houseInfo.houseGUID, houseInfo.plotID)
    else
        C_Housing.ReturnAfterVisitingHouse()
    end
end

-- Установка иконки пункту списка
local function setIcon(frame, data)
    if not frame.icon then
        frame.icon = CreateFrame("Frame", nil, frame)
        frame.icon:SetSize(32, 32)
        frame.icon:SetPoint("LEFT", 10, 0)
    end

    if not frame.icon.texture then
        frame.icon.texture = frame.icon:CreateTexture(nil, "ARTWORK")
        frame.icon.texture:Hide()
    end

    if not frame.icon.border then
        frame.icon.border = frame.icon:CreateTexture(nil, "OVERLAY")
        frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -6, 6)
        frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 6, -6)
        frame.icon.border:SetAtlas("plunderstorm-actionbar-slot-border")
        frame.icon.border:Hide()
    else
        frame.icon.border:Hide()
    end

    if data.type == "item" or data.type == "spell" then
        frame.icon.texture:SetAllPoints()
        frame.icon.texture:SetTexture(data.texture)
        ApplyMaskToTexture(frame.icon.texture)
        frame.icon.border:Show()
        frame.icon.texture:Show()
    elseif data.type == "housing" then
        frame.icon.texture:SetAllPoints()
        frame.icon.texture:SetAtlas("dashboard-panel-homestone-teleport-button")
        ApplyMaskToTexture(frame.icon.texture)
        frame.icon.border:Show()
        frame.icon.texture:Show()
    else
        frame.icon.texture:Hide()
    end
end

-- Обновление фокуса
local function UpdateFocus(element, changeFocus)

    if not element then
        return
    end

    -- Сброс фокуса для всех элементов
    local frames = parentFrame.ScrollBox:GetFrames()
        for _, frame in ipairs(frames) do
        frame:SetFocused(false)
    end

    focusedIndex = parentFrame.ScrollBox:FindElementDataIndex(element)

    local frame = parentFrame.ScrollBox:FindFrameByPredicate(function(frame, elementData)
		return elementData == element;
	end)
    
    if frame and changeFocus then
        frame:SetFocused(true)
    end

    -- Прокрутить ScrollBox до текущего элемента
    if gamePadActive then
        parentFrame.ScrollBox:ScrollToElementDataIndex(focusedIndex)
    end

    -- Устанавливаем бинд: при нажатии PAD1 будет использоваться предмет, 
    local bindString

    if element.type == "item" then
        bindString = "ITEM " .. element.name
    elseif element.type == "spell" then
        bindString = "SPELL " .. element.name
    elseif element.type == "housing" then
        currentHouseInfo = element.houseInfo
        bindString = "CLICK FastTravelHousingTeleportButton:LeftButton"
    end

    SetOverrideBinding(
        parentFrame, -- владелец бинда
        true, 
        "PAD1", 
        bindString
    )
end

-- Функция переключения фокуса
local function MoveFocus(delta)
    local newIndex = math.max(1, math.min(focusedIndex + delta, FastTravelScrollBox:GetDataProviderSize()))
    local element = parentFrame.ScrollBox:GetDataProvider().collection[newIndex]
    UpdateFocus(element, true)
end

-- Создание ScrollBox
local function CreateFastTravelScrollBox()

    local FastTravelScrollBox = ConsoleMenuFrame.FastTravel

    local ScrollBox = CreateFrame("Frame", "FastTravelScrollBox", FastTravelScrollBox, "WowScrollBoxList")
    FastTravelScrollBox.ScrollBox = ScrollBox
    ScrollBox:SetPoint("TOPLEFT", FastTravelScrollBox, "TOPLEFT", 0, -sectionHeight)
    ScrollBox:SetPoint("BOTTOMRIGHT", FastTravelScrollBox, "BOTTOMRIGHT", 0, sectionHeight)

    local ScrollBar = CreateFrame("EventFrame", "FastTravelScrollBar", FastTravelScrollBox, "MinimalScrollBar")
    FastTravelScrollBox.ScrollBox.ScrollBar = ScrollBar

    ScrollBar:SetPoint("TOPLEFT", ScrollBox, "TOPRIGHT")
    ScrollBar:SetPoint("BOTTOMLEFT", ScrollBox, "BOTTOMRIGHT")

    local DataProvider = CreateDataProvider()
    local ScrollView = CreateScrollBoxListLinearView()

    -- Обновление видимости скролл бара
    local function UpdateScrollBarVisibility()
        local totalHeight = ScrollView:GetExtent() - 1
        if totalHeight <= FastTravelScrollBox:GetHeight() then
            FastTravelScrollBar:Hide()
        else
            FastTravelScrollBar:Show()
        end
    end

    -- Инициализатор для элемента списка
    local function Initializer(frame, data)

        if not data then
            -- Если по какой-то причине data == nil, не вставляем во frames
            return
        end

        local hearthstoneButton = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate")
        frame.SecureActionButton = hearthstoneButton

        hearthstoneButton:SetAllPoints(frame)
        hearthstoneButton:RegisterForClicks("AnyDown")
        
        -- Включаем обработку мыши для переключения фокуса при наведении
        hearthstoneButton:EnableMouse(true)

        -- -- Настройка атрибутов для SecureActionButton
        -- if data.type == "item" then
        --     frame.SecureActionButton:SetAttribute("type", "item")
        --     frame.SecureActionButton:SetAttribute("item", data.name)
        -- elseif data.type == "spell" then
        --     frame.SecureActionButton:SetAttribute("type", "spell")
        --     frame.SecureActionButton:SetAttribute("spell", data.name)
        -- elseif data.type == "housing" then
        --     -- Для housing используем OnClick, так как нет стандартного атрибута
        --     frame.SecureActionButton:SetScript("OnClick", function(self, button)
        --         TeleportToHouse(data.houseInfo)
        --     end)
        -- end
        
        -- Обработчик наведения мыши для переключения фокуса
        hearthstoneButton:SetScript("OnEnter", function(self)
            UpdateFocus(data, false)
            frame:SetFocused(true)
        end)

        -- Иконка
        if not frame.icon then
            frame.icon = CreateFrame("Frame", nil, frame)
            frame.icon:SetSize(iconSize, iconSize)
            frame.icon:SetPoint("LEFT", sectionPadding, 0)
        end

        setIcon(frame, data)

        -- Текст
        if not frame.text then
            frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.text:SetPoint("LEFT", frame.icon, "RIGHT", sectionPadding * 1.5, 0)
            frame.text:SetPoint("RIGHT", -sectionPadding, 0)
            frame.text:SetJustifyH("LEFT")
        end

        frame.text:SetFont("Fonts\\FRIZQT___CYR.TTF", itemFontSize, "OUTLINE")
        frame.text:SetText(data.name)
        frame.text:SetTextColor(1, 0.976, 0.855) -- Цвет текста FFF9DA

        -- Тень (фон)
        if not frame.bg then
            frame.bg = frame:CreateTexture(nil, "BACKGROUND")
            frame.bg:SetAllPoints()
            frame.bg:SetAtlas("Garr_BuildingInfoShadow")
            frame.bg:Hide()
        end

        function frame:SetFocused(isFocused)
            if isFocused then
                frame.bg:Show()
            else
                frame.bg:Hide()
            end
        end

    end

    -- Наполнение списка элементами
    local function SetItemList()
        DataProvider:Flush()

        -- Обновляем списки заклинаний для вкладок мага, если они существуют
        if classFile == "MAGE" and tabs[1] and tabs[3] and tabs[4] then
            if IsInGroup() then
                tabs[1].spells = mageSpells.actual.group
                tabs[3].spells = mageSpells.azeroth.group
                tabs[4].spells = mageSpells.world.group
            else
                tabs[1].spells = mageSpells.actual.single
                tabs[3].spells = mageSpells.azeroth.single
                tabs[4].spells = mageSpells.world.single
            end
        elseif classFile == "DEATHKNIGHT" and tabs[1] then
            tabs[1].spells = deathknightSpells
        end
    
        if focusedTab == 1 then
            -- Добавляем камень возвращения
            local itemInfo = 6948
            local itemName, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemInfo)
            DataProvider:Insert({
                id = itemInfo,
                type = "item",
                name = itemName,
                texture = itemTexture,
            })

            -- Добавляем телепорты в жилище / из него
            if C_Housing then
                local teleportToPlot = true
            
                if C_HousingNeighborhood.CanReturnAfterVisitingHouse() then
                    local currentNeighborhoodGUID = C_Housing.GetCurrentNeighborhoodGUID()
                    if currentNeighborhoodGUID and C_Housing.GetCurrentHouseInfo() and currentNeighborhoodGUID == C_Housing.GetCurrentHouseInfo().neighborhoodGUID then
                        teleportToPlot = false
                    end
                end

                if teleportToPlot then
                    texture = "dashboard-panel-homestone-teleport-button"
                    for _, houseInfo in ipairs(houseList) do
                        DataProvider:Insert({
                            id = houseInfo.houseGUID,
                            type = "housing",
                            name = houseInfo.houseName,
                            houseInfo = houseInfo,
                        })
                    end
                end
            end

            local spells = tabs[focusedTab].spells or {}

            for _, spellID in ipairs(spells) do
                if IsSpellKnown(spellID) then
                    -- Получаем инфо о заклинании
                    local spellInfo = C_Spell.GetSpellInfo(spellID)

                    DataProvider:Insert({
                        id = spellInfo.spellID,
                        type = "spell",
                        name = spellInfo.name,
                        texture = spellInfo.iconID,
                    })
                end
            end
        else
            local spells = tabs[focusedTab].spells or {}

            for _, spellID in ipairs(spells) do
                if IsSpellKnown(spellID) then
                    -- Получаем инфо о заклинании
                    local spellInfo = C_Spell.GetSpellInfo(spellID)

                    DataProvider:Insert({
                        id = spellInfo.spellID,
                        type = "spell",
                        name = spellInfo.name,
                        texture = spellInfo.iconID,
                    })
                end
            end
        end
    
        UpdateScrollBarVisibility()
    end

    ScrollView:SetElementExtent(sectionHeight)
    ScrollView:SetElementInitializer("Button", Initializer, "SecureActionButtonTemplate")

    ScrollUtil.InitScrollBoxListWithScrollBar(ScrollBox, ScrollBar, ScrollView)
    ScrollBox:SetDataProvider(DataProvider)

    FastTravelScrollBox:Hide()

    return FastTravelScrollBox, SetItemList
end

-- Функция предзагрузки данных
local function PreloadData()
    local itemsToPreload = {
        6948,    -- Hearthstone
    }

    for _, itemID in ipairs(itemsToPreload) do
        -- Создаём объект Item
        local itemObj = Item:CreateFromItemID(itemID)
        -- Запрашиваем загрузку данных
        itemObj:ContinueOnItemLoad(function()
           
        end)
    end

    local spells = {}

    local className, classFile = UnitClass("player")
    if classFile == "MAGE" then
        for _, spellID in ipairs(mageSpells.azeroth.single) do
            table.insert(spells, spellID)
        end
        for _, spellID in ipairs(mageSpells.azeroth.group) do
            table.insert(spells, spellID)
        end
        for _, spellID in ipairs(mageSpells.world.single) do
            table.insert(spells, spellID)
        end
        for _, spellID in ipairs(mageSpells.world.group) do
            table.insert(spells, spellID)
        end
    elseif classFile == "DEATHKNIGHT" then
        for _, spellID in ipairs(deathknightSpells) do
            table.insert(spells, spellID)
        end
    end

    for _, spellID in ipairs(spells) do
        C_Spell.RequestLoadSpellData(spellID)
    end

    C_Housing.GetPlayerOwnedHouses()
end

-- Обновление фреймов вкладок в зависимости от фокуса
local function UpdateTabs()
    for i = 1, #tabs do
        local tab = _G["FastTravelTab" .. i]
        if not tab then
            return
        end
        if i == focusedTab then
            tab.circle:Hide()
            tab.text:Show()
            -- Установка ширины таба по ширине текста
            local textWidth = tab.text:GetStringWidth()
            tab:SetWidth(textWidth)
        else
            tab.circle:Show()
            tab.text:Hide()

            local diff = math.abs(focusedTab - i)

            if diff == 1 then
                tab.circle:SetSize(sectionPadding, sectionPadding)
                tab:SetWidth(sectionPadding)
            else
                local newSize = sectionPadding * ((#tabs - diff) / #tabs + 0.35)
                tab.circle:SetSize(newSize, newSize)
                tab:SetWidth(newSize)
            end
        end
    end
end

-- Функция для смены текущей вкладки
local function SwitchTab(direction)
    local tabCount = #tabs
    local newTabIndex = focusedTab + direction

    if newTabIndex < 1 then
        newTabIndex = 1
    elseif newTabIndex > tabCount then
        newTabIndex = tabCount
    end

    focusedTab = newTabIndex
    UpdateTabs()
end

function ConsoleMenu:SetFastTravelFrame()
    PreloadData()

    if ConsoleMenuFrame.FastTravel then
        return
    end

    local FastTravel = CreateFrame("Frame", "FastTravel", ConsoleMenuFrame)
    ConsoleMenuFrame.FastTravel = FastTravel
    ConsoleMenu:InitFadeAnimations(FastTravel, animationDuration)

    FastTravel:SetSize(frameWidth, sectionHeight * (viewedItemCount + 2))
    FastTravel:SetPoint("BOTTOMLEFT", ConsoleMenuFrame, "BOTTOMLEFT", 48, 48)
    
    -- Включаем обработку клавиатуры для ESC
    FastTravel:EnableKeyboard(true)
    FastTravel:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            ConsoleMenu:AnimatedHide(self)
        end
    end)

    FastTravel:RegisterEvent("PLAYER_REGEN_DISABLED") -- Начало боя
    FastTravel:RegisterUnitEvent("UNIT_SPELLCAST_START", "player") -- Игрок начал каст
    FastTravel:RegisterEvent("GAME_PAD_ACTIVE_CHANGED") -- Событие изменения режима геймпада
    FastTravel:RegisterEvent("PLAYER_HOUSE_LIST_UPDATED")

    FastTravel:SetScript("OnEvent", function(self, event, ...)
        if event == "GAME_PAD_ACTIVE_CHANGED" then
            gamePadActive = ...
            return
        end

        if event == "PLAYER_HOUSE_LIST_UPDATED" then
            houseList = ...
            return
        end

        if FastTravel:IsShown() then
            FastTravel:Hide()
        end
    end)

    -- Создаем заголовок
    FastTravel.Title = CreateFrame("Frame", "FastTravelTitle", FastTravel)
    FastTravel.Title:SetPoint("TOPLEFT", FastTravel, "TOPLEFT", 0, 0)
    FastTravel.Title:SetPoint("TOPRIGHT", FastTravel, "TOPRIGHT", 0, 0)
    FastTravel.Title:SetHeight(sectionHeight)

    FastTravel.Title.Text = FastTravel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    FastTravel.Title.Text:SetPoint("LEFT", FastTravelTitle, "LEFT", sectionPadding, 0)
    FastTravel.Title.Text:SetPoint("RIGHT", FastTravelTitle, "RIGHT", sectionPadding, 0)
    FastTravel.Title.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "OUTLINE")
    FastTravel.Title.Text:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
    FastTravel.Title.Text:SetText("Быстрое перемещение")
    FastTravel.Title.Text:SetJustifyH("LEFT")

    -- Создаём ScrollBox
    parentFrame, setItemList = CreateFastTravelScrollBox()

    -- Создаем вкладки
    InitTabs()

    FastTravel.Tabs = CreateFrame("Frame", "FastTravelTabs", FastTravel)
    FastTravel.Tabs:SetPoint("BOTTOMLEFT", FastTravel, "BOTTOMLEFT", 0, 0)
    FastTravel.Tabs:SetPoint("BOTTOMRIGHT", FastTravel, "BOTTOMRIGHT", 0, 0)
    FastTravel.Tabs:SetHeight(sectionHeight)

    local previousTab = nil
    for i = 1, #tabs do
        local tab = CreateFrame("Button", "FastTravelTab" .. i, FastTravelTabs)
        if i == 1 then
            tab:SetPoint("LEFT", FastTravelTabs, "LEFT", sectionPadding, 0)
        else
            tab:SetPoint("LEFT", previousTab, "RIGHT", sectionPadding, 0)
        end

        -- Установка текста таба
        local text = tabs[i].title
        local tabFont = "Fonts\\FRIZQT___CYR.TTF"
        if not tab.text then
            tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            tab.text:SetFont(tabFont, tabFontSize, "OUTLINE")
            tab.text:SetTextColor(1.0, 0.960784, 0.772549, 0.4)
            tab.text:SetPoint("CENTER")
        end
        tab.text:SetText(text)

        -- Добавляем окружность в центр каждого таба
        if not tab.circle then
            tab.circle = CreateFrame("Frame", nil, tab)
            tab.circle:SetSize(sectionPadding, sectionPadding)
            tab.circle:SetPoint("CENTER", tab, "CENTER", 0, 0)
        
            -- Текстура заливки
            tab.circle.texture = tab.circle:CreateTexture(nil, "ARTWORK")
            tab.circle.texture:SetAllPoints(tab.circle)
            tab.circle.texture:SetColorTexture(1.0, 0.960784, 0.772549, 0.4)
            tab.circle.texture:SetTexCoord(0, 1, 0, 1)
        
            -- Маска круга
            tab.circle.mask = tab.circle:CreateMaskTexture()
            tab.circle.mask:SetAllPoints(tab.circle)
            tab.circle.mask:SetTexture(
                "Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png",
                "CLAMPTOBLACK"
            )
        
            -- Применяем маску
            tab.circle.texture:AddMaskTexture(tab.circle.mask)
        end

        tab.circle:Hide()

        -- Установка ширины таба по ширине текста
        local textWidth = tab.text:GetStringWidth()
        tab:SetWidth(textWidth)
        -- Установка высоты
        tab:SetHeight(sectionHeight)

        tab:SetScript("OnClick", function()
            focusedTab = i
            UpdateTabs()
            setItemList()
            local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
            UpdateFocus(element, true)
        end)

        previousTab = tab
    end

    UpdateTabs()

    -- Создаём «невидимые» кнопки для перемещения фокуса и скрытия окна:
    local focusUpButton = CreateFrame("Button", "FocusUpButton", parentFrame)
    focusUpButton:SetSize(1,1)  -- крошечная, невидимая
    focusUpButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT")
    focusUpButton:SetScript("OnClick", function()
        MoveFocus(-1)
    end)

    local focusDownButton = CreateFrame("Button", "FocusDownButton", parentFrame)
    focusDownButton:SetSize(1,1)
    focusDownButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 20)
    focusDownButton:SetScript("OnClick", function()
        MoveFocus(1)
    end)

    -- Кнопка для переключения вкладки влево
    local tabLeftButton = CreateFrame("Button", "FastTravelTabLeftButton", parentFrame)
    tabLeftButton:SetSize(1,1)
    tabLeftButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 80)
    tabLeftButton:SetScript("OnClick", function()
        SwitchTab(-1)
        setItemList()
        local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
        UpdateFocus(element, true)
    end)

    -- Кнопка для переключения вкладки вправо
    local tabRightButton = CreateFrame("Button", "FastTravelTabRightButton", parentFrame)
    tabRightButton:SetSize(1,1)
    tabRightButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 100)
    tabRightButton:SetScript("OnClick", function()
        SwitchTab(1)
        setItemList()
        local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
        UpdateFocus(element, true)
    end)

    local hideButton = CreateFrame("Button", "FastTravelHideButton", parentFrame)
    hideButton:SetSize(1,1)
    hideButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 40)
    hideButton:SetScript("OnClick", function()
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.FastTravel)
    end)

    -- Кнопка для телепорта домой внутри housing
    local teleportButton = CreateFrame("Button", "FastTravelHousingTeleportButton", parentFrame)
    teleportButton:SetSize(1, 1)
    teleportButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 60)
    teleportButton:SetScript("OnClick", function(self)
        TeleportToHouse()
    end)

    -- Вешаем бинды, когда окно показывается:
    parentFrame:HookScript("OnShow", function()
        softTargetEnemy = GetCVar("SoftTargetEnemy")
        SetCVar("SoftTargetEnemy", 0)
        
        -- Привязываем PADDUP к клику по FocusUpButton
        SetOverrideBindingClick(focusUpButton, true, "PADDUP", "FocusUpButton", "LeftButton")
        -- Привязываем PADDDOWN к клику по FocusDownButton
        SetOverrideBindingClick(focusDownButton, true, "PADDDOWN", "FocusDownButton", "LeftButton")

        -- Привязываем PADLEFT к клику по FastTravelTabLeftButton
        SetOverrideBindingClick(tabLeftButton, true, "PADDLEFT", "FastTravelTabLeftButton", "LeftButton")
        -- Привязываем PADRIGHT к клику по FastTravelTabRightButton
        SetOverrideBindingClick(tabRightButton, true, "PADDRIGHT", "FastTravelTabRightButton", "LeftButton")

        -- Привязываем PAD2 к клику по FastTravelHideButton (чтобы закрывать окно)
        SetOverrideBindingClick(hideButton, true, "PAD2", "FastTravelHideButton", "LeftButton")

        UpdateFocus(parentFrame.ScrollBox:GetDataProvider().collection[1], true)

        if WeakAuras then
            WeakAuras.ScanEvents("CHANGE_CONTEXT", "window")
            WeakAuras.ScanEvents("SHOW_FAST_TRAVEL_FRAME", true)
        end

    end)

    -- Очищаем бинды, когда окно скрывается:
    parentFrame:HookScript("OnHide", function()
        if softTargetEnemy then
            SetCVar("SoftTargetEnemy", softTargetEnemy)
        end
        
        ClearOverrideBindings(parentFrame)
        ClearOverrideBindings(focusUpButton)
        ClearOverrideBindings(focusDownButton)
        ClearOverrideBindings(hideButton)
        ClearOverrideBindings(tabLeftButton)
        ClearOverrideBindings(tabRightButton)

        if WeakAuras then
            WAGlobal = WAGlobal or {}  -- Создаем таблицу, если её ещё нет
            local previousContext = WAGlobal.previousContext or "exploring"
            WeakAuras.ScanEvents("CHANGE_CONTEXT", previousContext)
            WeakAuras.ScanEvents("SHOW_FAST_TRAVEL_FRAME", false)
        end

    end)
    
end

-- Слеш-команда
SLASH_FASTTRAVEL1 = "/fasttravel"
SlashCmdList["FASTTRAVEL"] = function()
    if parentFrame and parentFrame:IsShown() then
        return
    end

    if not parentFrame then
        ConsoleMenu:SetFastTravelFrame()
    end

    if parentFrame then
        setItemList()
        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.FastTravel)
    end
end
