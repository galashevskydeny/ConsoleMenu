-- Раскладка кнопок: положения по клавишам и видимость страницы.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Ячейка относится к текущей странице основной панели.
local function IsSlotOnActiveActionBarPage(slotID)
    return ActionBar.IsSlotOnActivePage(slotID)
end

-- Нужно ли показывать кнопку при текущей дополнительной клавише.
local function IsActionButtonVisible(slotID, btn, activeModifier)
    if not slotID or not btn then
        return false
    end
    if ActionBar.IsBoostSlot(slotID) then
        return false
    end

    if ActionBar.IsExtraActionSlot(slotID) then
        return false
    end

    -- Вне боя без удержания клавиш обычные кнопки скрыты.
    if ConsoleMenu.GetPlayerContext and ConsoleMenu:GetPlayerContext() == "exploring" and not activeModifier then
        return false
    end

    if ActionBar.ignoredSlot[slotID] or not ActionBar.buttonPositions[btn.mainKey] then
        return false
    end

    -- Подсказка тачпада (слот 12): только при наличии действия и названия
    if ActionBar.slot12Slots[slotID] then
        if not C_ActionBar.HasAction(slotID) then
            return false
        end
        local actionType, id, subType = GetActionInfo(slotID)
        if not ConsoleMenu:GetSlotTitle(actionType, id, subType, slotID) then
            return false
        end
    end

    -- Кнопки основной панели остаются на экране: переворот и серый цвет делает сама кнопка.
    -- Вне боя при зажатой клавише берём боевую страницу, третья страница этих кнопок не содержит.
    if slotID >= 1 and slotID <= 24 then
        if btn.modifierKey then
            return false
        end
        if activeModifier and ConsoleMenu.GetPlayerContext and ConsoleMenu:GetPlayerContext() == "exploring" then
            return ActionBar.IsSlotOnCombatPage(slotID)
        end
        return IsSlotOnActiveActionBarPage(slotID)
    end

    -- Умение дополнительной панели рисует перевёрнутая кнопка, вторая копия не нужна.
    return false
end

-- Текущая удерживаемая дополнительная клавиша.
-- Ctrl важнее Shift: вместе они оставляют переворот панели, а не облако усилений.
local function GetActiveModifier()
    if not IsModifierKeyDown() then
        return nil
    end
    if IsControlKeyDown() then
        return "CTRL"
    end
    if IsShiftKeyDown() then
        return "SHIFT"
    end
    if IsAltKeyDown() then
        return "ALT"
    end
    return nil
end

-- Кнопка занимает место на панели, поэтому чужое свечение может уменьшить её иконку.
-- Островок тачпада в этом уменьшении не участвует, поэтому его название здесь не спрашиваем.
function ActionBar.IsShiftButtonVisible(btn)
    if not btn or not btn.slotID then
        return false
    end
    if ActionBar.slot12Slots and ActionBar.slot12Slots[btn.slotID] then
        return false
    end
    local activeModifier = GetActiveModifier()
    if IsActionButtonVisible(btn.slotID, btn, activeModifier) then
        return true
    end
    -- В исследовании обычные кнопки скрыты, но переворачивающаяся кнопка крестовины остаётся.
    return ActionBar.IsActiveBoostHostSlot and ActionBar.IsActiveBoostHostSlot(btn.slotID)
end

-- Записывает в таблицу группы кнопки, которые нужно показать. Таблица готова до показа и скрытия.
local function FillGroupTable(group, showPanel, activeModifier)
    if not group or not group.visibleButtons or not group.buttons then
        return
    end
    local list = group.visibleButtons
    for index = #list, 1, -1 do
        list[index] = nil
    end
    for index = 1, #group.buttons do
        local btn = group.buttons[index]
        if showPanel and IsActionButtonVisible(btn.slotID, btn, activeModifier) then
            list[#list + 1] = btn
        end
    end
end

-- Ставит кнопку на место раскладки вместе с уже набранным сдвигом.
local function PlaceButton(btn)
    if ActionBar.SeatButton then
        ActionBar.SeatButton(btn)
    end
end

-- Привязка кнопок к положениям. Номера ячеек берутся из таблицы каждой кнопки.
local function UpdateButtonPositions(slotID)
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    if ActionBar.FillButtonSlots then
        ActionBar.FillButtonSlots()
    end

    if slotID then
        local btn = ActionBar.GetButton(slotID)
        if not btn then
            return
        end
        local position = ActionBar.buttonPositions[btn.mainKey]
        local anchor = position and ActionBar.ResolveAnchor(frame, position[2])
        if anchor and not (ActionBar.ignoredSlot[btn.slotID] == true) then
            PlaceButton(btn)
        end
        if btn.Update then
            btn:Update()
        end
        return
    end

    for _, btn in pairs(frame.actionButtons) do
        local position = ActionBar.buttonPositions[btn.mainKey]
        local anchor = position and ActionBar.ResolveAnchor(frame, position[2])
        if anchor and not (ActionBar.ignoredSlot[btn.slotID] == true) then
            PlaceButton(btn)
        end
        if btn.Update then
            btn:Update()
        end
    end
end


-- Показывает кадр сразу, без затухания.
local function ShowNow(frame)
    if not frame then
        return
    end
    if frame.fadeOut then
        frame.fadeOut:Stop()
        frame.fadeOut:SetScript("OnFinished", nil)
    end
    if frame.fadeIn then
        frame.fadeIn:Stop()
    end
    frame:Show()
    frame:SetAlpha(1)
end

-- Прячет кадр сразу и возвращает полную непрозрачность.
local function HideNow(frame)
    if not frame then
        return
    end
    if frame.fadeOut then
        frame.fadeOut:Stop()
        frame.fadeOut:SetScript("OnFinished", nil)
    end
    if frame.fadeIn then
        frame.fadeIn:Stop()
    end
    frame:Hide()
    frame:SetAlpha(1)
end

-- Панель нужна, когда её просят показать. В исследовании без дополнительной клавиши кнопки скрыты.
local function PanelButtonsWanted(frame, activeModifier)
    if not frame or frame.barDesired == false then
        return false
    end
    if ConsoleMenu.GetPlayerContext and ConsoleMenu:GetPlayerContext() == "exploring" and not activeModifier then
        return false
    end
    return true
end

-- Прячет кадр панели, когда все кнопки уже скрылись.
local function HidePanelFrameIfIdle(frame, activeModifier)
    if not frame or not frame.actionButtons then
        return
    end
    if PanelButtonsWanted(frame, activeModifier) then
        return
    end
    for _, btn in pairs(frame.actionButtons) do
        if btn:IsShown() then
            return
        end
    end
    HideNow(frame)
end

-- После исчезновения кнопки прячет панель, если показывать её больше не нужно.
function ActionBar.AfterButtonHidden()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end
    HidePanelFrameIfIdle(frame, GetActiveModifier())
end

-- Иконка без модификатора уже стоит на экране.
local function BaseIconDisplayed(btn)
    if not btn:IsShown() or btn.hiding or btn.scaleZero then
        return false
    end
    if math.abs((btn:GetScale() or 1) - 1) >= 0.02 then
        return false
    end
    local slots = btn.IconFrame and btn.IconFrame.slots
    local base = (slots and slots.base) or btn.slotID
    if not base or btn.shownSlot ~= base then
        return false
    end
    local texture = btn.shownTexture
    if ActionBar.IsSecretValue and ActionBar.IsSecretValue(texture) then
        return true
    end
    return texture ~= nil and texture ~= ""
end

-- Смена набора кнопок при удержании дополнительной клавиши.
-- Размер панели не меняется: видимые кнопки сами вырастают, лишние сами исчезают.
local function UpdateModifierState()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    if ActionBar.RememberCombatPage then
        ActionBar.RememberCombatPage()
    end

    local activeModifier = GetActiveModifier()
    if frame.barDesired == false then
        activeModifier = nil
    end
    local showPanel = PanelButtonsWanted(frame, activeModifier)
    if showPanel then
        ShowNow(frame)
    end

    FillGroupTable(frame.rightGroup, showPanel, activeModifier)
    FillGroupTable(frame.leftGroup, showPanel, activeModifier)

    for _, btn in pairs(frame.actionButtons) do
        local visible = showPanel and IsActionButtonVisible(btn.slotID, btn, activeModifier)
        if not btn.modifierKey and ActionBar.SetButtonModifier then
            if activeModifier and not btn.heldModifier then
                btn.baseIconShown = BaseIconDisplayed(btn)
            end
            local releasing = btn.heldModifier and not (visible and activeModifier)
            local settled = btn:IsShown() and not btn.hiding and not btn.scaleZero and math.abs((btn:GetScale() or 1) - 1) < 0.02
            -- До нажатия своей иконки не было: при скрытии рисунок не переворачиваем.
            if releasing and not visible and not btn.baseIconShown and btn:IsShown() then
                btn.keepFaceOnHide = true
            end
            local instant = (not settled) or (releasing and not btn.baseIconShown)
            ActionBar.SetButtonModifier(btn, visible and activeModifier or nil, instant)
        end
    end

    if frame.rightGroup and frame.rightGroup.ShowGroup then
        frame.rightGroup:ShowGroup()
        frame.rightGroup:HideGroup()
    end
    if frame.leftGroup and frame.leftGroup.ShowGroup then
        frame.leftGroup:ShowGroup()
        frame.leftGroup:HideGroup()
    end

    for _, btn in pairs(frame.actionButtons) do
        if not btn.group then
            local visible = showPanel and IsActionButtonVisible(btn.slotID, btn, activeModifier)
            if visible then
                ActionBar.ShowButton(btn)
            else
                ActionBar.HideButton(btn)
            end
        end
    end

    if ActionBar.UpdateClouds then
        ActionBar.UpdateClouds()
    end
    if ActionBar.RefreshFaceButtonDesaturation then
        ActionBar.RefreshFaceButtonDesaturation()
    end
    if ActionBar.SyncGlowButtonSizes then
        ActionBar.SyncGlowButtonSizes()
    end
    HidePanelFrameIfIdle(frame, activeModifier)
    if ActionBar.WakeClouds then
        ActionBar.WakeClouds()
    end
end

ActionBar.UpdateButtonPositions = UpdateButtonPositions
ActionBar.UpdateModifierState = UpdateModifierState
