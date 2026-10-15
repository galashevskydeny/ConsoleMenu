-- Раскладка кнопок: положения по клавишам, видимость страницы и тени групп.

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

    -- Низ левой крестовины: без модификатора это левый рычаг, с модификатором — направление вниз.
    local stickKey = ActionBar.leftStickKey
    local frame = ActionBar.GetFrame()
    local stick = stickKey and frame and frame.actionButtons and frame.actionButtons[stickKey]
    if stick and btn.mainKey == "PADDDOWN" and not activeModifier then
        return false
    end
    if stick and btn.mainKey == stickKey and activeModifier then
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

-- Кнопка сейчас занимает место на панели. Скрытая страница и чужой модификатор в сдвиг не входят.
-- Островок тачпада в сдвиге не участвует, поэтому его название здесь не спрашиваем.
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

-- Обычный размер ареола. После исчезновения панели его нужно вернуть, иначе тень остаётся точкой.
local function RestoreGroupShadowSize(shadow)
    if not shadow then
        return
    end
    local home = ActionBar.shadowSize
    if not home or home < 1 then
        return
    end
    if shadow.lastSize == home then
        return
    end
    shadow:SetSize(home, home)
    shadow.lastSize = home
end

-- Включает ареол группы один раз: повторный вызов не перезапускает проявление.
local function SetGroupShadowShown(shadow, shown)
    if not shadow then
        return
    end
    if shadow.groupShown == shown then
        return
    end
    shadow.groupShown = shown
    if shown then
        RestoreGroupShadowSize(shadow)
        ConsoleMenu:AnimatedShow(shadow)
    else
        ConsoleMenu:AnimatedHide(shadow)
    end
end

-- Показ и скрытие теней левой и правой групп кнопок.
local function UpdateActionButtonShadows()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    local activeModifier = GetActiveModifier()

    local PADcount = 0
    local PADDcount = 0

    for _, btn in pairs(frame.actionButtons) do
        local slotID = btn.slotID
        local position = ActionBar.buttonPositions[btn.mainKey]
        local shownSlot = slotID
        if btn.boostShowingAlt and btn.boostFlipSlot then
            shownSlot = btn.boostFlipSlot
        end
        if slotID and position and C_ActionBar.HasAction(shownSlot) and IsActionButtonVisible(slotID, btn, activeModifier) then
            if position[2] == "right" then
                PADcount = PADcount + 1
            elseif position[2] == "left" then
                PADDcount = PADDcount + 1
            end
        end
    end

    local cloudVisible = ActionBar.HasVisibleBoosts and ActionBar.HasVisibleBoosts()
    SetGroupShadowShown(frame.PADshadow, PADcount > 0 or cloudVisible)
    SetGroupShadowShown(frame.PADDshadow, PADDcount > 0)
    frame.shadowCloudVisible = cloudVisible and true or false
    ActionBar.shadowsDirty = nil
end

-- Пересчитывает тени, только если сменилась видимость облака или сторона монеты.
local function UpdateActionButtonShadowsIfNeeded()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    local cloudVisible = ActionBar.HasVisibleBoosts and ActionBar.HasVisibleBoosts() or false
    if not ActionBar.shadowsDirty and frame.shadowCloudVisible == cloudVisible then
        return
    end

    UpdateActionButtonShadows()
end

-- Ставит кнопку на место раскладки и оставляет уже набранный сдвиг к тёмной противоположной.
local function PlaceButton(btn, position, anchor)
    if ActionBar.SeatButton then
        ActionBar.SeatButton(btn)
        return
    end
    local shiftX, shiftY = 0, 0
    if ActionBar.ButtonGlowShift then
        shiftX, shiftY = ActionBar.ButtonGlowShift(btn)
    end
    local scale = btn:GetScale() or 1
    btn:ClearAllPoints()
    btn:SetPoint(
        position[1],
        anchor,
        position[3],
        ActionBar.StableOffset(position[4] + shiftX, scale),
        ActionBar.StableOffset(position[5] + shiftY, scale)
    )
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
            PlaceButton(btn, position, anchor)
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
            PlaceButton(btn, position, anchor)
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

    for _, btn in pairs(frame.actionButtons) do
        local visible = showPanel and IsActionButtonVisible(btn.slotID, btn, activeModifier)
        if not btn.modifierKey and ActionBar.SetButtonModifier then
            local settled = btn:IsShown() and not btn.hiding and not btn.scaleZero and math.abs((btn:GetScale() or 1) - 1) < 0.02
            ActionBar.SetButtonModifier(btn, visible and activeModifier or nil, not settled)
        end
        if visible then
            ActionBar.ShowButton(btn)
        else
            ActionBar.HideButton(btn)
        end
    end

    if ActionBar.UpdateClouds then
        ActionBar.UpdateClouds()
    end
    UpdateActionButtonShadows()
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
ActionBar.UpdateActionButtonShadows = UpdateActionButtonShadows
ActionBar.UpdateActionButtonShadowsIfNeeded = UpdateActionButtonShadowsIfNeeded
