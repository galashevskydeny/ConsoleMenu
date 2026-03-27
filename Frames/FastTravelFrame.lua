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
local focusedTab = "favorites"
local tabs = {}

local houseList = {}
local currentHouseInfo = nil

local softTargetEnemy
local gamePadActive = false

local mageSpells = {
    azeroth = {
        single = {1259190, 446540, 395277, 281403, 281404, 224869, 193759, 132621, 132627, 88342, 88344, 53140, 32272, 3561, 3567, 3562, 3563, 3565, 3566, 49359, 49358, 120145},
        group = {1259194, 446534, 395289, 281400, 281402, 224871, 193759, 132620, 132626, 88345, 88346, 53142, 32267, 10059, 11417, 11416, 11418, 11419, 11420, 49361, 49360, 120146}
    },
    world = {
        single = {344587, 176248, 176242, 35715, 33690},
        group = {344597, 176246, 176244, 33691, 35717}
    },
    actual = {
        single = {1259190},
        group = {1259194}
    }
}

local deathknightSpells = {
    50977,
}

local monkSpells = {
    126892,
}

local hearthstonesToys = {
    265100, 263933, 246565, 190196, 257736, 209035, 245970, 200630, 172179, 168907, 182773, 188952, 208704, 193588, 236687, 184353, 180290, 228940, 165802, 162973, 163045, 166746, 165669, 166747, 210952
}

-- Возвращает случайную игрушку из hearthstonesToys, которой владеет персонаж
local function GetRandomOwnedHearthstoneToy()
    local ownedToys = {}
    for _, toyID in ipairs(hearthstonesToys) do
        if PlayerHasToy(toyID) then
            table.insert(ownedToys, toyID)
        end
    end

    if #ownedToys == 0 then
        return nil -- у персонажа нет ни одной игрушки из списка
    end

    return ownedToys[math.random(#ownedToys)]
end

-- Функция для получения отсортированного списка ключей вкладок
local function GetTabOrder()
    local orderedKeys = {}
    for key, tab in pairs(tabs) do
        table.insert(orderedKeys, { key = key, order = tab.order })
    end
    table.sort(orderedKeys, function(a, b) return a.order < b.order end)
    local result = {}
    for _, item in ipairs(orderedKeys) do
        table.insert(result, item.key)
    end
    return result
end

-- Функция для инициализации вкладок
local function InitTabs()
    local order = 1
    
    -- Создаем вкладки
    tabs["favorites"] = { title = "Избранное", key = "favorites", order = order }
    order = order + 1

    local flyoutSpellID = 244
    _, _, numSlots, isKnown = GetFlyoutInfo(flyoutSpellID)

    if isKnown then
        tabs["hero"] = { title = "Путь героя", spells = {}, key = "hero", order = order }
        order = order + 1
        for i = 1, numSlots do
            local flyoutSpellID, _, isKnown, _, _ = GetFlyoutSlotInfo(flyoutSpellID, i)
            if flyoutSpellID and isKnown then
                table.insert(tabs["hero"].spells, flyoutSpellID)
            end
        end
    end 

    if classFile == "MAGE" then
        tabs["azeroth"] = { title = "Азерот", spells = {}, key = "azeroth", order = order }
        order = order + 1
        tabs["world"] = { title = "Мир", spells = {}, key = "world", order = order }
        order = order + 1
    end
end

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
        frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -6, 6)
        frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 6, -6)
        frame.icon.border:SetAtlas("plunderstorm-actionbar-slot-border")
        frame.icon.border:Hide()
    else
        frame.icon.border:Hide()
    end

    frame.icon.texture:SetAllPoints()
    frame.icon.texture:SetTexture(data.texture)
    ApplyMaskToTexture(frame.icon.texture)
    frame.icon.border:Show()
    frame.icon.texture:Show()
end

-- Обновление фокуса
local function UpdateFocus(element, changeFocus)
    if not element then return end
    if InCombatLockdown() then return end

    local frames = parentFrame.ScrollBox:GetFrames()
    for _, frame in ipairs(frames) do
        frame:SetFocused(false)
    end

    focusedIndex = parentFrame.ScrollBox:FindElementDataIndex(element)

    local frame = parentFrame.ScrollBox:FindFrameByPredicate(function(frame, elementData)
        return elementData == element
    end)

    if not frame then return end

    if changeFocus then
        frame:SetFocused(true)
    end

    if gamePadActive then
        parentFrame.ScrollBox:ScrollToElementDataIndex(focusedIndex)
    end

    if element.type == "item" then
        FastTravelActiveButton:SetAttribute("type", "item")
        FastTravelActiveButton:SetAttribute("item", element.name)
    elseif element.type == "spell" then
        FastTravelActiveButton:SetAttribute("type", "spell")
        FastTravelActiveButton:SetAttribute("spell", element.id)
    elseif element.type == "randomhearthstone" then
        FastTravelActiveButton:SetAttribute("type", "toy")
        local randomToy = GetRandomOwnedHearthstoneToy()
        print(randomToy)
        FastTravelActiveButton:SetAttribute("toy", randomToy)
    end

    bindString = "CLICK FastTravelActiveButton:LeftButton"
    SetOverrideBinding(
        FastTravel, -- владелец бинда
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

        if not data or not frame then return end

        -- Иконка
        if not frame.icon then
            frame.icon = CreateFrame("Frame", nil, frame)
            frame.icon:SetSize(iconSize, iconSize)
            frame.icon:SetPoint("LEFT", sectionPadding, 0)
        end

        SetIcon(frame, data)

        -- Текст
        if not frame.text then
            frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.text:SetPoint("LEFT", frame.icon, "RIGHT", sectionPadding * 1.5, -2)
            frame.text:SetPoint("RIGHT", -sectionPadding, -2)
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
        if classFile == "MAGE" and tabs["favorites"] and tabs["azeroth"] and tabs["world"] then
            if IsInGroup() then
                tabs["favorites"].spells = mageSpells.actual.group
                tabs["azeroth"].spells = mageSpells.azeroth.group
                tabs["world"].spells = mageSpells.world.group
            else
                tabs["favorites"].spells = mageSpells.actual.single
                tabs["azeroth"].spells = mageSpells.azeroth.single
                tabs["world"].spells = mageSpells.world.single
            end
        elseif classFile == "DEATHKNIGHT" and tabs["favorites"] then
            tabs["favorites"].spells = deathknightSpells
        elseif classFile == "MONK" and tabs["favorites"] then
            tabs["favorites"].spells = monkSpells
        end
    
        if focusedTab == "favorites" then
            -- Добавляем камень возвращения
            local itemInfo = 6948
            local itemName, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemInfo)

            DataProvider:Insert({
                id = "randomhearthstone",
                type = "randomhearthstone",
                name = itemName,
                texture = itemTexture,
            })

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
    elseif classFile == "MONK" then
        for _, spellID in ipairs(monkSpells) do
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
    local tabOrder = GetTabOrder()
    local focusedTabIndex = 1
    for i, tabKey in ipairs(tabOrder) do
        if tabKey == focusedTab then
            focusedTabIndex = i
            break
        end
    end
    
    for i, tabKey in ipairs(tabOrder) do
        local tab = _G["FastTravelTab" .. i]
        if not tab then
            return
        end
        if tabKey == focusedTab then
            tab.circle:Hide()
            tab.text:Show()
            -- Установка ширины таба по ширине текста
            local textWidth = tab.text:GetStringWidth()
            tab:SetWidth(textWidth)
        else
            tab.circle:Show()
            tab.text:Hide()

            local diff = math.abs(focusedTabIndex - i)

            if diff == 1 then
                tab.circle:SetSize(sectionPadding, sectionPadding)
                tab:SetWidth(sectionPadding)
            else
                local newSize = sectionPadding * ((#tabOrder - diff) / #tabOrder + 0.35)
                tab.circle:SetSize(newSize, newSize)
                tab:SetWidth(newSize)
            end
        end
    end
end

-- Функция для смены текущей вкладки
local function SwitchTab(direction)
    local tabOrder = GetTabOrder()
    local currentIndex = 1
    for i, tabKey in ipairs(tabOrder) do
        if tabKey == focusedTab then
            currentIndex = i
            break
        end
    end
    
    local tabCount = #tabOrder
    local newTabIndex = currentIndex + direction

    if newTabIndex < 1 then
        newTabIndex = 1
    elseif newTabIndex > tabCount then
        newTabIndex = tabCount
    end

    focusedTab = tabOrder[newTabIndex]
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

    FastTravel.Background = FastTravel:CreateTexture(nil, "BACKGROUND")
    FastTravel.Background:SetWidth(800)
    FastTravel.Background:SetHeight(400)
    FastTravel.Background:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -290, -40)
    FastTravel.Background:SetAtlas("MapCornerShadow-Right")
    FastTravel.Background:SetTexCoord(1, 0, 0, 1) -- Отразить по горизонтали
    FastTravel.Background:SetAlpha(0.85)
    
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
    FastTravel.Title.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "")
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
    local tabOrder = GetTabOrder()
    for i, tabKey in ipairs(tabOrder) do
        local tab = CreateFrame("Button", "FastTravelTab" .. i, FastTravelTabs)
        if i == 1 then
            tab:SetPoint("LEFT", FastTravelTabs, "LEFT", sectionPadding, 0)
        else
            tab:SetPoint("LEFT", previousTab, "RIGHT", sectionPadding, 0)
        end

        -- Установка текста таба
        local text = tabs[tabKey].title
        local tabFont = "Fonts\\FRIZQT___CYR.TTF"
        if not tab.text then
            tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            tab.text:SetFont(tabFont, tabFontSize, "")
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
            focusedTab = tabKey
            UpdateTabs()
            setItemList()
            local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
            UpdateFocus(element, true)
        end)

        previousTab = tab
    end

    UpdateTabs()

    FastTravel.SecureActionButton = CreateFrame("Button", "FastTravelActiveButton", FastTravel, "SecureActionButtonTemplate")
    FastTravel.SecureActionButton:SetAttribute("useOnKeyDown", false)
    FastTravel.SecureActionButton:RegisterForClicks("AnyUp", "AnyDown")
    FastTravel.SecureActionButton:SetAllPoints()

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

    end)

    -- Очищаем бинды, когда окно скрывается:
    parentFrame:HookScript("OnHide", function()
        if softTargetEnemy then
            SetCVar("SoftTargetEnemy", softTargetEnemy)
        end

        if InCombatLockdown() then return end
        
        ClearOverrideBindings(parentFrame)
        ClearOverrideBindings(focusUpButton)
        ClearOverrideBindings(focusDownButton)
        ClearOverrideBindings(hideButton)
        ClearOverrideBindings(tabLeftButton)
        ClearOverrideBindings(tabRightButton)

        ConsoleMenu:DeleteKeysFrameItem("PAD1", "Выбрать")
        ConsoleMenu:DeleteKeysFrameItem("PAD2", "Выйти")
        ConsoleMenu:DeleteKeysFrameItem("PADDLEFTRIGHT", "Переключение вкладок")

        ConsoleMenu:RemoveWindow("fasttravel")
        ConsoleMenu:ApplyContextUIChanges()

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
        ConsoleMenu:AddWindow("fasttravel")
        ConsoleMenu:ApplyContextUIChanges()  
    end
end
