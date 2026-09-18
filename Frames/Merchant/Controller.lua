-- Вкладки, кнопки контроллера и отложенная пересборка списка торговца.

local ConsoleMenu = _G.ConsoleMenu
local Merchant = ConsoleMenu.Merchant
local ExpandableList = ConsoleMenu.ExpandableList

-- Вкладки торговли, продажи и выкупа.
function Merchant.BuildTabs()
    Merchant.tabs = {
        { title = "Торговля", code = "trade" },
        { title = "Продажа", code = "sell" },
        { title = "Выкуп", code = "buyback" },
    }
end

-- Запомнить выбранную строку текущей вкладки.
function Merchant.SaveCurrentTabFocus()
    local tab = Merchant.tabs[Merchant.focusedTabIndex]
    local list = Merchant.GetList()
    if not tab or not list then
        return
    end
    local element = list:GetFocusedElement()
    Merchant.tabFocus[tab.code] = {
        slot = element and element.slot,
        bag = element and element.bag,
        type = element and element.type,
        index = list.focusedIndex,
    }
end

-- Загрузить содержимое вкладки в список.
function Merchant.LoadTabData(tab)
    Merchant.ClearTooltipCache()
    Merchant.ClearStackSizeCache()
    local list = Merchant.GetList()
    if not list then
        return
    end

    local elements, emptyTitle, emptyDescription = Merchant.BuildTabData(tab)
    local selectableCount = 0
    for index = 1, #elements do
        if Merchant.IsListItem(elements[index]) then
            selectableCount = selectableCount + 1
        end
    end
    list:SetElements(elements)
    list:SetEmpty(emptyTitle, emptyDescription, selectableCount == 0)
    Merchant.PreloadNearFocusedOrFirst()
end

-- Восстановить выбранную строку текущей вкладки.
function Merchant.RestoreCurrentTabFocus()
    local tab = Merchant.tabs[Merchant.focusedTabIndex]
    local list = Merchant.GetList()
    if not list then
        return
    end

    local saved = tab and Merchant.tabFocus[tab.code]
    local restored = nil
    if saved and saved.slot and saved.type then
        restored = list:RestoreFocus(function(element)
            return Merchant.MatchesFocus(element, saved.slot, saved.type, saved.bag)
        end, saved.index)
    else
        restored = list:FocusFirst()
    end

    if not restored then
        Merchant.UpdateActionKeys(nil)
        ConsoleMenu:UpdateKeysFrame()
    end
end

-- Обновить внешний вид вкладок по выбранной.
function Merchant.UpdateTabs()
    local frame = Merchant.GetFrame()
    local tabButtons = frame and frame.TabButtons
    if not tabButtons then
        return
    end

    for index = 1, #Merchant.tabs do
        local tabButton = tabButtons[index]
        if not tabButton then
            return
        end
        if index == Merchant.focusedTabIndex then
            tabButton.circle:Hide()
            tabButton.text:Show()
            tabButton:SetWidth(tabButton.text:GetStringWidth())
        else
            tabButton.circle:Show()
            tabButton.text:Hide()
            local diff = math.abs(Merchant.focusedTabIndex - index)
            if diff == 1 then
                tabButton.circle:SetSize(ExpandableList.sectionPadding, ExpandableList.sectionPadding)
                tabButton:SetWidth(ExpandableList.sectionPadding)
            else
                local newSize = ExpandableList.sectionPadding * ((#Merchant.tabs - diff) / #Merchant.tabs + 0.35)
                tabButton.circle:SetSize(newSize, newSize)
                tabButton:SetWidth(newSize)
            end
        end
    end
end

-- Расставить вкладки и подписи.
function Merchant.RefreshTabsLayout()
    local frame = Merchant.GetFrame()
    local tabButtons = frame and frame.TabButtons
    local tabsHost = frame and frame.Tabs
    if not tabButtons or not tabsHost then
        return
    end

    local previousTab = nil
    for index = 1, #Merchant.tabs do
        local tabButton = tabButtons[index]
        local tabData = Merchant.tabs[index]
        if tabButton and tabData then
            tabButton.text:SetText(tabData.title)
            tabButton:Show()
            tabButton:ClearAllPoints()
            if index == 1 then
                tabButton:SetPoint("LEFT", tabsHost, "LEFT", ExpandableList.sectionPadding * 1.5, 0)
            else
                tabButton:SetPoint("LEFT", previousTab, "RIGHT", ExpandableList.sectionPadding, 0)
            end
            previousTab = tabButton
        end
    end

    for index = #Merchant.tabs + 1, Merchant.merchantTabSlotCount do
        local tabButton = tabButtons[index]
        if tabButton then
            tabButton:Hide()
        end
    end

    if Merchant.focusedTabIndex > #Merchant.tabs then
        Merchant.focusedTabIndex = 1
    end

    Merchant.UpdateTabs()
end

-- Выбрать вкладку по номеру и восстановить её выбор.
function Merchant.SelectTab(index)
    if index < 1 or index > #Merchant.tabs then
        return
    end

    Merchant.SaveCurrentTabFocus()
    Merchant.focusedTabIndex = index
    Merchant.LoadTabData(Merchant.tabs[index])
    Merchant.UpdateTabs()
    Merchant.RestoreCurrentTabFocus()
end

-- Переключить вкладку влево или вправо.
function Merchant.SwitchTab(direction)
    if #Merchant.tabs == 0 then
        return
    end

    local newTabIndex = Merchant.focusedTabIndex + direction
    if newTabIndex < 1 then
        newTabIndex = #Merchant.tabs
    elseif newTabIndex > #Merchant.tabs then
        newTabIndex = 1
    end

    Merchant.SelectTab(newTabIndex)
end

-- Одна отложенная пересборка списка по событиям торговца.
function Merchant.ScheduleRefresh(rebuildTabs)
    Merchant.merchantRefreshRebuildTabs = Merchant.merchantRefreshRebuildTabs or rebuildTabs
    if Merchant.merchantRefreshQueued then
        return
    end

    Merchant.merchantRefreshQueued = true
    C_Timer.After(0, function()
        Merchant.merchantRefreshQueued = false
        local needTabs = Merchant.merchantRefreshRebuildTabs
        Merchant.merchantRefreshRebuildTabs = false

        local frame = Merchant.GetFrame()
        if not frame then
            return
        end

        if needTabs then
            Merchant.BuildTabs()
            Merchant.focusedTabIndex = 1
            Merchant.tabFocus = {}
            Merchant.RefreshTabsLayout()
        else
            Merchant.SaveCurrentTabFocus()
        end

        local tab = Merchant.tabs[Merchant.focusedTabIndex]
        if tab then
            Merchant.LoadTabData(tab)
        end

        Merchant.LoadCurrenciesData()
        Merchant.UpdateCurrenciesFrame()
        Merchant.RestoreCurrentTabFocus()
    end)
end

-- Переназначение кнопок контроллера.
function Merchant.ApplyOverrideBindings(frame)
    if not frame then
        return
    end

    if InCombatLockdown() then
        Merchant.pendingOverrideBindings = true
        return
    end

    Merchant.pendingOverrideBindings = false
    Merchant.pendingClearOverrideBindings = false

    SetOverrideBindingClick(frame.FocusUpButton, true, "PADDUP", frame.FocusUpButton:GetName(), "LeftButton")
    SetOverrideBindingClick(frame.FocusDownButton, true, "PADDDOWN", frame.FocusDownButton:GetName(), "LeftButton")
    SetOverrideBindingClick(frame.TabLeftButton, true, "PADDLEFT", frame.TabLeftButton:GetName(), "LeftButton")
    SetOverrideBindingClick(frame.TabRightButton, true, "PADDRIGHT", frame.TabRightButton:GetName(), "LeftButton")
    SetOverrideBindingClick(frame.PrimaryButton, true, "PAD1", frame.PrimaryButton:GetName(), "LeftButton")
    SetOverrideBindingClick(frame.SecondaryButton, true, "PAD4", frame.SecondaryButton:GetName(), "LeftButton")
    SetOverrideBindingClick(frame.TertiaryButton, true, "PAD3", frame.TertiaryButton:GetName(), "LeftButton")
    SetOverrideBindingClick(frame.CloseButton, true, "PAD2", frame.CloseButton:GetName(), "LeftButton")
end

-- Снять переназначение кнопок контроллера.
function Merchant.ClearOverrideBindings(frame)
    if not frame then
        return
    end

    if InCombatLockdown() then
        Merchant.pendingClearOverrideBindings = true
        return
    end

    Merchant.pendingClearOverrideBindings = false
    Merchant.pendingOverrideBindings = false

    ClearOverrideBindings(frame)
    local buttons = {
        frame.FocusUpButton,
        frame.FocusDownButton,
        frame.TabLeftButton,
        frame.TabRightButton,
        frame.PrimaryButton,
        frame.SecondaryButton,
        frame.TertiaryButton,
        frame.CloseButton,
    }
    for _, button in ipairs(buttons) do
        if button then
            ClearOverrideBindings(button)
        end
    end
end

-- Создать невидимую кнопку контроллера.
local function CreateBindingButton(frame, fieldName, globalName, offsetY, onClick)
    if frame[fieldName] then
        return frame[fieldName]
    end

    local button = CreateFrame("Button", globalName, frame, "SecureActionButtonTemplate")
    frame[fieldName] = button
    button:SetAttribute("useOnKeyDown", false)
    button:RegisterForClicks("LeftButtonUp")
    button:SetSize(1, 1)
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, offsetY)
    button:SetScript("OnClick", onClick)
    return button
end

-- Создать кнопки контроллера окна торговца.
function Merchant.CreateControllerButtons(frame)
    CreateBindingButton(frame, "FocusUpButton", "ConsoleMenuMerchantFocusUpButton", 0, function()
        local list = Merchant.GetList()
        if list then
            list:MoveFocus(-1)
        end
    end)
    CreateBindingButton(frame, "FocusDownButton", "ConsoleMenuMerchantFocusDownButton", 20, function()
        local list = Merchant.GetList()
        if list then
            list:MoveFocus(1)
        end
    end)
    CreateBindingButton(frame, "TabLeftButton", "ConsoleMenuMerchantTabLeftButton", 100, function()
        Merchant.SwitchTab(-1)
    end)
    CreateBindingButton(frame, "TabRightButton", "ConsoleMenuMerchantTabRightButton", 120, function()
        Merchant.SwitchTab(1)
    end)
    CreateBindingButton(frame, "PrimaryButton", "ConsoleMenuMerchantPrimaryButton", 40, function()
        Merchant.PrimaryAction()
    end)
    CreateBindingButton(frame, "SecondaryButton", "ConsoleMenuMerchantSecondaryButton", 80, function()
        Merchant.SecondaryAction()
    end)
    CreateBindingButton(frame, "TertiaryButton", "ConsoleMenuMerchantTertiaryButton", 140, function()
        Merchant.TertiaryAction()
    end)
    CreateBindingButton(frame, "CloseButton", "ConsoleMenuMerchantCloseButton", 60, function()
        CloseMerchant()
    end)
end

-- Создать полосу вкладок полями окна, без поиска по глобальным именам.
function Merchant.CreateTabs(frame)
    if frame.Tabs then
        return frame.Tabs
    end

    frame.Tabs = CreateFrame("Frame", "ConsoleMenuMerchantTabs", frame)
    frame.Tabs:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 26, 0)
    frame.Tabs:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.Tabs:SetHeight(ExpandableList.sectionHeight)
    frame.TabButtons = {}

    local previousTab = nil
    for index = 1, Merchant.merchantTabSlotCount do
        local tabButton = CreateFrame("Button", nil, frame.Tabs)
        frame.TabButtons[index] = tabButton
        if index == 1 then
            tabButton:SetPoint("LEFT", frame.Tabs, "LEFT", ExpandableList.sectionPadding * 1.5, 0)
        else
            tabButton:SetPoint("LEFT", previousTab, "RIGHT", ExpandableList.sectionPadding, 0)
        end

        tabButton.text = tabButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabButton.text:SetFont(ExpandableList.fontName, Merchant.tabFontSize, "")
        tabButton.text:SetTextColor(1.0, 0.960784, 0.772549, 0.4)
        tabButton.text:SetPoint("CENTER")

        tabButton.circle = CreateFrame("Frame", nil, tabButton)
        tabButton.circle:SetSize(ExpandableList.sectionPadding, ExpandableList.sectionPadding)
        tabButton.circle:SetPoint("CENTER", tabButton, "CENTER", 0, 0)
        tabButton.circle.texture = tabButton.circle:CreateTexture(nil, "ARTWORK")
        tabButton.circle.texture:SetAllPoints(tabButton.circle)
        tabButton.circle.texture:SetColorTexture(1.0, 0.960784, 0.772549, 0.4)
        tabButton.circle.mask = tabButton.circle:CreateMaskTexture()
        tabButton.circle.mask:SetAllPoints(tabButton.circle)
        tabButton.circle.mask:SetTexture(ExpandableList.circleMaskPath, ExpandableList.maskWrapMode)
        tabButton.circle.texture:AddMaskTexture(tabButton.circle.mask)
        tabButton.circle:Hide()
        tabButton:SetHeight(ExpandableList.sectionHeight)
        tabButton:Hide()

        tabButton:SetScript("OnClick", function()
            Merchant.SelectTab(index)
        end)

        previousTab = tabButton
    end

    return frame.Tabs
end
