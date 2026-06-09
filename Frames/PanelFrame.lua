-- PanelFrame.lua

local ConsoleMenu = _G.ConsoleMenu
local parentFrame
local setItemList

local frameWidth = 480
local viewedItemCount = 3
local sectionHeight = 56
local sectionPadding = 8
local iconSize = sectionHeight - sectionPadding * 2
local titleFontSize = 20
local tabFontSize = 18
local itemFontSize = 20

local animationDuration = 0.1

local gamePadActive = false
local focusedIndex = 1
local focusedTab = nil
local tabs = {}
local usePresetTabs = true

local panelTitle = "Панель команд"
local actionBarFirstSlot = 1
local actionBarSlotCount = 12

local panelsByNumber = {
    [6] = { "Наряды", 145 },
    [7] = { "Полезности", 157 },
    [8] = { "Перемещение", 169 },
}

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

-- Инициализация вкладок панели
local function InitTabs()
    tabs = {}
    local order = 1

    local panelNumbers = {}
    for panelNumber in pairs(panelsByNumber) do
        table.insert(panelNumbers, panelNumber)
    end
    table.sort(panelNumbers)

    for _, panelNumber in ipairs(panelNumbers) do
        local panelData = panelsByNumber[panelNumber]
        local title = panelData and panelData[1]
        local firstSlot = panelData and panelData[2]
        if title and firstSlot then
            local key = tostring(panelNumber)
            tabs[key] = {
                key = key,
                title = title,
                firstSlot = firstSlot,
                slotCount = actionBarSlotCount,
                order = order,
            }
            order = order + 1
        end
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
        frame.icon.border:Hide()
    else
        frame.icon.border:Hide()
    end

    if data.type == "spell" then
        frame.icon.border:SetAtlas("spellbook-item-iconframe")
        frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -13, 3)
        frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 3, -9)
    else
        frame.icon.border:SetAtlas("plunderstorm-actionbar-slot-border")
        frame.icon.border:SetPoint("TOPLEFT", frame.icon.texture, "TOPLEFT", -8, 8)
        frame.icon.border:SetPoint("BOTTOMRIGHT", frame.icon.texture, "BOTTOMRIGHT", 8, -8)
    end

    frame.icon.texture:SetAllPoints()
    frame.icon.texture:SetTexture(data.texture)
    frame.icon.texture:SetDesaturated(data.isLackingResources or false)
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

    PanelActiveButton:SetAttribute("type", "action")
    PanelActiveButton:SetAttribute("action", element.id)

    local bindString = "CLICK PanelActiveButton:LeftButton"
    SetOverrideBinding(
        PanelFrame, -- владелец бинда
        true, 
        "PAD1", 
        bindString
    )

end

-- Функция переключения фокуса
local function MoveFocus(delta)
    local newIndex = math.max(1, math.min(focusedIndex + delta, PanelScrollBox:GetDataProviderSize()))
    local element = parentFrame.ScrollBox:GetDataProvider().collection[newIndex]
    UpdateFocus(element, true)
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
        local tab = _G["PanelTab" .. i]
        if not tab then
            return
        end
        if tabKey == focusedTab then
            tab.circle:Hide()
            tab.text:Show()
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
    if #tabOrder == 0 then
        return
    end

    local currentIndex = 1
    for i, tabKey in ipairs(tabOrder) do
        if tabKey == focusedTab then
            currentIndex = i
            break
        end
    end

    local newTabIndex = currentIndex + direction
    if newTabIndex < 1 then
        newTabIndex = 1
    elseif newTabIndex > #tabOrder then
        newTabIndex = #tabOrder
    end

    focusedTab = tabOrder[newTabIndex]
    usePresetTabs = true
    local selectedTab = tabs[focusedTab]
    if selectedTab then
        actionBarFirstSlot = selectedTab.firstSlot
        actionBarSlotCount = selectedTab.slotCount
    end
    UpdateTabs()
end

-- Создание ScrollBox
local function CreatePanelScrollBox()

    local PanelScrollBox = ConsoleMenuFrame.PanelFrame

    local ScrollBox = CreateFrame("Frame", "PanelScrollBox", PanelScrollBox, "WowScrollBoxList")
    PanelScrollBox.ScrollBox = ScrollBox
    ScrollBox:SetPoint("TOPLEFT", PanelScrollBox, "TOPLEFT", 0, -sectionHeight)
    ScrollBox:SetPoint("BOTTOMRIGHT", PanelScrollBox, "BOTTOMRIGHT", 0, sectionHeight)

    local ScrollBar = CreateFrame("EventFrame", "PanelScrollBar", PanelScrollBox, "MinimalScrollBar")
    PanelScrollBox.ScrollBox.ScrollBar = ScrollBar

    ScrollBar:SetPoint("TOPLEFT", ScrollBox, "TOPRIGHT")
    ScrollBar:SetPoint("BOTTOMLEFT", ScrollBox, "BOTTOMRIGHT")

    local DataProvider = CreateDataProvider()
    local ScrollView = CreateScrollBoxListLinearView()

    -- Обновление видимости скролл бара
    local function UpdateScrollBarVisibility()
        local totalHeight = ScrollView:GetExtent() - 1
        if totalHeight <= PanelScrollBox:GetHeight() then
            PanelScrollBar:Hide()
        else
            PanelScrollBar:Show()
        end
    end

    -- Инициализатор для элемента списка
    local function Initializer(frame, data)

        if not data or not frame then return end

        -- Иконка
        if not frame.icon then
            frame.icon = CreateFrame("Frame", nil, frame)
            frame.icon:SetSize(iconSize, iconSize)
            frame.icon:SetPoint("LEFT", sectionPadding * 1.5, 0)
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

        if usePresetTabs and (not focusedTab or not tabs[focusedTab]) then
            focusedTab = GetTabOrder()[1]
        end

        if usePresetTabs and focusedTab and tabs[focusedTab] then
            local selectedTab = tabs[focusedTab]
            actionBarFirstSlot = selectedTab.firstSlot
            actionBarSlotCount = selectedTab.slotCount
        end

        if ConsoleMenuFrame.PanelFrame and ConsoleMenuFrame.PanelFrame.Title and ConsoleMenuFrame.PanelFrame.Title.Text then
            ConsoleMenuFrame.PanelFrame.Title.Text:SetText(panelTitle)
        end

        for i = 0, actionBarSlotCount - 1 do
            local actionID = actionBarFirstSlot + i
            if C_ActionBar.HasAction(actionID) then
                local actionType, identifier = GetActionInfo(actionID)
                local name = ""

                if actionType == "outfit" then
                    local outfitInfo = C_TransmogOutfitInfo.GetOutfitInfo(identifier)
                    name = outfitInfo.name
                elseif actionType == "macro" then
                    local macroName = C_Macro.GetMacroName(identifier)
                    name = macroName or ""
                elseif actionType == "summonmount" then
                    if identifier == 268435455 then
                        name = "Избранный маунт"
                    else
                        name = C_MountJournal.GetMountInfoByID(identifier)
                    end
                elseif actionType == "spell" then
                    name = C_Spell.GetSpellInfo(identifier).name
                elseif actionType == "item" then
                    name = C_Item.GetItemNameByID(identifier)
                elseif actionType == "summonpet" then
                    local _, _, _, _, _, _, _, petName = C_PetJournal.GetPetInfoByPetID(identifier)
                    name = petName
                end

                DataProvider:Insert({
                    id = actionID,
                    type = actionType,
                    name = name,
                    texture = C_ActionBar.GetActionTexture(actionID),
                })
            end
        end

        UpdateScrollBarVisibility()
    end

    ScrollView:SetElementExtent(sectionHeight)
    ScrollView:SetElementInitializer("Button", Initializer, "SecureActionButtonTemplate")

    ScrollUtil.InitScrollBoxListWithScrollBar(ScrollBox, ScrollBar, ScrollView)
    ScrollBox:SetDataProvider(DataProvider)

    PanelScrollBox:Hide()

    return PanelScrollBox, SetItemList
end

-- Функция предзагрузки данных
local function PreloadData()

end

function ConsoleMenu:SetPanelFrame()
    PreloadData()

    if ConsoleMenuFrame.PanelFrame then
        return
    end

    local PanelFrame = CreateFrame("Frame", "PanelFrame", ConsoleMenuFrame)
    ConsoleMenuFrame.PanelFrame = PanelFrame
    ConsoleMenu:InitFadeAnimations(PanelFrame, animationDuration)

    PanelFrame:SetSize(frameWidth, sectionHeight * (viewedItemCount + 2))
    PanelFrame:SetPoint("BOTTOMLEFT", ConsoleMenuFrame, "BOTTOMLEFT", 48, 48)

    PanelFrame.Background = PanelFrame:CreateTexture(nil, "BACKGROUND")
    PanelFrame.Background:SetWidth(800)
    PanelFrame.Background:SetHeight(400)
    PanelFrame.Background:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -290, -40)
    PanelFrame.Background:SetAtlas("MapCornerShadow-Right")
    PanelFrame.Background:SetTexCoord(1, 0, 0, 1) -- Отразить по горизонтали
    PanelFrame.Background:SetAlpha(0.85)
    
    -- Включаем обработку клавиатуры для ESC
    PanelFrame:EnableKeyboard(true)
    PanelFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            ConsoleMenu:AnimatedHide(self)
        end
    end)

    PanelFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Начало боя
    PanelFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player") -- Игрок начал каст
    PanelFrame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player") -- Игрок отправил каст
    PanelFrame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED") -- Событие изменения режима геймпада
    PanelFrame:RegisterEvent("TRANSMOG_DISPLAYED_OUTFIT_CHANGED") -- Событие изменения отображаемого наряда
    PanelFrame:RegisterEvent("COMPANION_UPDATE") -- Событие изменения питомца

    PanelFrame:SetScript("OnEvent", function(self, event, ...)
        local unit = ...

        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_SENT" then
            if unit ~= "player" then
                return
            end
        end

        if event == "GAME_PAD_ACTIVE_CHANGED" then
            gamePadActive = unit
            return
        end

        if event == "COMPANION_UPDATE" then
            if unit ~= "CRITTER" then
                return
            end
        end

        if PanelFrame:IsShown() then
            PanelFrame:Hide()
        end
    end)

    -- Создаем заголовок
    PanelFrame.Title = CreateFrame("Frame", "PanelFrameTitle", PanelFrame)
    PanelFrame.Title:SetPoint("TOPLEFT", PanelFrame, "TOPLEFT", 0, 0)
    PanelFrame.Title:SetPoint("TOPRIGHT", PanelFrame, "TOPRIGHT", 0, 0)
    PanelFrame.Title:SetHeight(sectionHeight)

    PanelFrame.Title.Text = PanelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    PanelFrame.Title.Text:SetPoint("LEFT", PanelFrameTitle, "LEFT", sectionPadding * 1.5, 0)
    PanelFrame.Title.Text:SetPoint("RIGHT", PanelFrameTitle, "RIGHT", sectionPadding, 0)
    PanelFrame.Title.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "")
    PanelFrame.Title.Text:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
    PanelFrame.Title.Text:SetText(panelTitle)
    PanelFrame.Title.Text:SetJustifyH("LEFT")

    -- Создаём ScrollBox
    parentFrame, setItemList = CreatePanelScrollBox()

    -- Создаем вкладки
    InitTabs()
    if not focusedTab or not tabs[focusedTab] then
        focusedTab = GetTabOrder()[1]
    end

    PanelFrame.Tabs = CreateFrame("Frame", "PanelTabs", PanelFrame)
    PanelFrame.Tabs:SetPoint("BOTTOMLEFT", PanelFrame, "BOTTOMLEFT", 0, 0)
    PanelFrame.Tabs:SetPoint("BOTTOMRIGHT", PanelFrame, "BOTTOMRIGHT", 0, 0)
    PanelFrame.Tabs:SetHeight(sectionHeight)

    local previousTab = nil
    local tabOrder = GetTabOrder()
    for i, tabKey in ipairs(tabOrder) do
        local tab = CreateFrame("Button", "PanelTab" .. i, PanelTabs)
        if i == 1 then
            tab:SetPoint("LEFT", PanelTabs, "LEFT", sectionPadding * 1.5, 0)
        else
            tab:SetPoint("LEFT", previousTab, "RIGHT", sectionPadding, 0)
        end

        local text = tabs[tabKey].title
        local tabFont = "Fonts\\FRIZQT___CYR.TTF"
        if not tab.text then
            tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            tab.text:SetFont(tabFont, tabFontSize, "")
            tab.text:SetTextColor(1.0, 0.960784, 0.772549, 0.4)
            tab.text:SetPoint("CENTER")
        end
        tab.text:SetText(text)

        if not tab.circle then
            tab.circle = CreateFrame("Frame", nil, tab)
            tab.circle:SetSize(sectionPadding, sectionPadding)
            tab.circle:SetPoint("CENTER", tab, "CENTER", 0, 0)

            tab.circle.texture = tab.circle:CreateTexture(nil, "ARTWORK")
            tab.circle.texture:SetAllPoints(tab.circle)
            tab.circle.texture:SetColorTexture(1.0, 0.960784, 0.772549, 0.4)
            tab.circle.texture:SetTexCoord(0, 1, 0, 1)

            tab.circle.mask = tab.circle:CreateMaskTexture()
            tab.circle.mask:SetAllPoints(tab.circle)
            tab.circle.mask:SetTexture(
                "Interface\\AddOns\\ConsoleMenu\\Assets\\MaskCircle.png",
                "CLAMPTOBLACK"
            )

            tab.circle.texture:AddMaskTexture(tab.circle.mask)
        end

        tab.circle:Hide()
        tab:SetWidth(tab.text:GetStringWidth())
        tab:SetHeight(sectionHeight)

        tab:SetScript("OnClick", function()
            focusedTab = tabKey
            usePresetTabs = true
            local selectedTab = tabs[focusedTab]
            if selectedTab then
                actionBarFirstSlot = selectedTab.firstSlot
                actionBarSlotCount = selectedTab.slotCount
                PanelFrame.Title.Text:SetText(panelTitle)
            end
            UpdateTabs()
            setItemList()
            local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
            UpdateFocus(element, true)
        end)

        previousTab = tab
    end

    UpdateTabs()

    PanelFrame.SecureActionButton = CreateFrame("Button", "PanelActiveButton", PanelFrame, "SecureActionButtonTemplate")
    PanelFrame.SecureActionButton:SetAttribute("useOnKeyDown", false)
    PanelFrame.SecureActionButton:RegisterForClicks("AnyUp", "AnyDown")
    PanelFrame.SecureActionButton:SetAllPoints()

    -- Создаём «невидимые» кнопки для перемещения фокуса и скрытия окна:
    local focusUpButton = CreateFrame("Button", "PanelFocusUpButton", parentFrame)
    focusUpButton:SetSize(1,1)  -- крошечная, невидимая
    focusUpButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT")
    focusUpButton:SetScript("OnClick", function()
        MoveFocus(-1)
    end)

    local focusDownButton = CreateFrame("Button", "PanelFocusDownButton", parentFrame)
    focusDownButton:SetSize(1,1)
    focusDownButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 20)
    focusDownButton:SetScript("OnClick", function()
        MoveFocus(1)
    end)

    local hideButton = CreateFrame("Button", "PanelHideButton", parentFrame)
    hideButton:SetSize(1,1)
    hideButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 40)
    hideButton:SetScript("OnClick", function()
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.PanelFrame)
    end)

    local tabLeftButton = CreateFrame("Button", "PanelTabLeftButton", parentFrame)
    tabLeftButton:SetSize(1,1)
    tabLeftButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 80)
    tabLeftButton:SetScript("OnClick", function()
        SwitchTab(-1)
        if PanelFrame.Title and PanelFrame.Title.Text then
            PanelFrame.Title.Text:SetText(panelTitle)
        end
        setItemList()
        local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
        UpdateFocus(element, true)
    end)

    local tabRightButton = CreateFrame("Button", "PanelTabRightButton", parentFrame)
    tabRightButton:SetSize(1,1)
    tabRightButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 100)
    tabRightButton:SetScript("OnClick", function()
        SwitchTab(1)
        if PanelFrame.Title and PanelFrame.Title.Text then
            PanelFrame.Title.Text:SetText(panelTitle)
        end
        setItemList()
        local element = parentFrame.ScrollBox:GetDataProvider().collection[1]
        UpdateFocus(element, true)
    end)

    -- Вешаем бинды, когда окно показывается:
    parentFrame:HookScript("OnShow", function()
        
        -- Привязываем PADDUP к клику по PanelFocusUpButton
        SetOverrideBindingClick(focusUpButton, true, "PADDUP", "PanelFocusUpButton", "LeftButton")
        -- Привязываем PADDDOWN к клику по PanelFocusDownButton
        SetOverrideBindingClick(focusDownButton, true, "PADDDOWN", "PanelFocusDownButton", "LeftButton")

        -- Привязываем PAD2 к клику по PanelHideButton (чтобы закрывать окно)
        SetOverrideBindingClick(hideButton, true, "PAD2", "PanelHideButton", "LeftButton")
        SetOverrideBindingClick(tabLeftButton, true, "PADDLEFT", "PanelTabLeftButton", "LeftButton")
        SetOverrideBindingClick(tabRightButton, true, "PADDRIGHT", "PanelTabRightButton", "LeftButton")

        local firstElement = parentFrame.ScrollBox:GetDataProvider().collection[1]
        if firstElement then
            UpdateFocus(firstElement, true)
        end

    end)

    -- Очищаем бинды, когда окно скрывается:
    parentFrame:HookScript("OnHide", function()

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

        ConsoleMenu:RemoveWindow("panel")
        ConsoleMenu:ApplyContextUIChanges()

    end)
    
end

-- Разбор аргумента: только номер панели, например /panel 6
local function ParsePanelNumber(msg)
    if not msg or msg:match("^%s*$") then
        return nil
    end

    local panelNumber = tonumber(strtrim(msg))
    if not panelNumber then
        return nil
    end

    if not panelsByNumber[panelNumber] then
        return nil
    end

    return panelNumber
end

-- Слеш-команда: /panel <номер_панели>
-- Пример: /panel 6
SLASH_PANEL1 = "/panel"
SlashCmdList["PANEL"] = function(msg)
    if parentFrame and parentFrame:IsShown() then
        return
    end

    local panelNumber = ParsePanelNumber(msg)
    usePresetTabs = true

    if panelNumber then
        local panelData = panelsByNumber[panelNumber]
        actionBarFirstSlot = panelData[2]
        actionBarSlotCount = 12
        focusedTab = tostring(panelNumber)
    elseif not focusedTab then
        focusedTab = GetTabOrder()[1]
    end

    if not parentFrame then
        ConsoleMenu:SetPanelFrame()
    end

    if parentFrame then
        UpdateTabs()
        if ConsoleMenuFrame.PanelFrame.Title and ConsoleMenuFrame.PanelFrame.Title.Text then
            ConsoleMenuFrame.PanelFrame.Title.Text:SetText(panelTitle)
        end
        setItemList()
        ConsoleMenu:AnimatedShow(ConsoleMenuFrame.PanelFrame)
        ConsoleMenu:AddWindow("panel")
        ConsoleMenu:ApplyContextUIChanges()
    end
end