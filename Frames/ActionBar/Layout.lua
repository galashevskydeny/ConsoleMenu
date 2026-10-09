-- Раскладка кнопок: положения по клавишам, видимость страницы и тени групп.

local ConsoleMenu = _G.ConsoleMenu
local ActionBar = ConsoleMenu.ActionBar

-- Ячейка относится к текущей странице основной панели.
local function IsSlotOnActiveActionBarPage(slotID)
    if slotID < 1 or slotID > 24 then
        return false
    end
    if not C_ActionBar or not C_ActionBar.GetActionBarPage then
        return true
    end

    local page = C_ActionBar.GetActionBarPage()
    local startSlot = 12 * (page - 1) + 1
    return slotID >= startSlot and slotID < startSlot + 12
end

-- Нужно ли показывать кнопку при текущей дополнительной клавише.
local function IsActionButtonVisible(slotID, btn, activeModifier)
    if ActionBar.IsBoostSlot(slotID) then
        return false
    end

    if ActionBar.IsExtraActionSlot(slotID) then
        return false
    end

    -- В исследовании без удержания клавиш обычные кнопки скрыты: видно только облако.
    if ConsoleMenu.GetPlayerContext and ConsoleMenu:GetPlayerContext() == "exploring" and not activeModifier then
        return false
    end

    if ActionBar.ignoredSlot[slotID] or not ActionBar.buttonPositions[btn.mainKey] then
        return false
    end

    -- В меню усилений на этом месте остаётся одна кнопка: она сама переворачивается.
    if ActionBar.IsBoostHostKey and ActionBar.IsBoostHostKey(btn.mainKey) and ActionBar.BoostFlipOwnsHosts and ActionBar.BoostFlipOwnsHosts() then
        return ActionBar.IsActiveBoostHostSlot and ActionBar.IsActiveBoostHostSlot(slotID)
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

    -- При правом рычаге квадрат, треугольник и круг основной панели не сменяются второй панелью.
    if activeModifier == "SHIFT" and ActionBar.IsMainFaceButtonKey(btn.mainKey) then
        if not btn.modifierKey and slotID >= 1 and slotID <= 24 then
            return IsSlotOnActiveActionBarPage(slotID)
        end
        return false
    end

    if slotID >= 1 and slotID <= 24 then
        if activeModifier then
            return false
        end
        return IsSlotOnActiveActionBarPage(slotID)
    end

    if activeModifier then
        return activeModifier == btn.modifierKey
    end

    return false
end

-- Текущая удерживаемая дополнительная клавиша.
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

-- Включает ареол группы один раз: повторный вызов не перезапускает проявление.
local function SetGroupShadowShown(shadow, shown)
    if not shadow or shadow.groupShown == shown then
        return
    end
    shadow.groupShown = shown
    if shown then
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

    for slotID, btn in pairs(frame.actionButtons) do
        local position = ActionBar.buttonPositions[btn.mainKey]
        if position and C_ActionBar.HasAction(slotID) and IsActionButtonVisible(slotID, btn, activeModifier) then
            if position[2] == "PADCenter" then
                PADcount = PADcount + 1
            elseif position[2] == "PADDCenter" then
                PADDcount = PADDcount + 1
            end
        end
    end

    local cloudVisible = ActionBar.HasVisibleBoosts and ActionBar.HasVisibleBoosts()
    SetGroupShadowShown(frame.PADshadow, PADcount > 0 or cloudVisible)
    SetGroupShadowShown(frame.PADDshadow, PADDcount > 0)
end

-- Привязка кнопок к положениям по назначению клавиш.
local function UpdateButtonPositions(slotID)
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    -- Обновление позиции конкретной кнопки (если передан slotID)
    if slotID then
        local btn = frame.actionButtons[slotID]
        if not btn then return end
        
        local command = ConsoleMenu:GetBindingCommandBySlotID(slotID)
        -- Раскладка панели всегда по клавишам контроллера, даже без подключённого геймпада.
        local binding = ConsoleMenu:GetCommandBinding(command, true)
        btn.binding = binding

        local mainKey, modifierKey = ConsoleMenu:ParseBindingKey(binding)
        btn.mainKey = mainKey
        btn.modifierKey = modifierKey

        local position = ActionBar.buttonPositions[btn.mainKey]

        if position and not (ActionBar.ignoredSlot[slotID] == true) then
            btn:ClearAllPoints()
            btn:SetPoint(position[1], position[2], position[3], position[4], position[5])
        end

        ActionBar.UpdateIcon(slotID)

        return
    end

    -- Обновление всех кнопок (если не передан slotID)
    for slotID, btn in pairs(frame.actionButtons) do
        local command = ConsoleMenu:GetBindingCommandBySlotID(slotID)
        -- Раскладка панели всегда по клавишам контроллера, даже без подключённого геймпада.
        local binding = ConsoleMenu:GetCommandBinding(command, true)
        btn.binding = binding

        local mainKey, modifierKey = ConsoleMenu:ParseBindingKey(binding)
        btn.mainKey = mainKey
        btn.modifierKey = modifierKey

        local position = ActionBar.buttonPositions[btn.mainKey]
        if position and not (ActionBar.ignoredSlot[slotID] == true) then
            btn:ClearAllPoints()
            btn:SetPoint(position[1], position[2], position[3], position[4], position[5])
        end

        ActionBar.UpdateIcon(slotID)
    end
end

-- В исследовании панель видна при Ctrl, Shift или при заполненной дополнительной кнопке действия.
local function UpdateExploringFrameVisibility(activeModifier)
    local contextData = ConsoleMenuFrame and ConsoleMenuFrame.PlayerContext
    if not contextData then
        return
    end
    if ConsoleMenu:GetPlayerContext() ~= "exploring" then
        return
    end

    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    if ActionBar.IsExploringCloudHiding and ActionBar.IsExploringCloudHiding() then
        return
    end

    if activeModifier == "CTRL" or activeModifier == "SHIFT" or ActionBar.HasVisibleExtraAction() then
        ConsoleMenu:AnimatedShow(frame)
    else
        ConsoleMenu:AnimatedHide(frame)
    end
end

-- Смена набора кнопок при удержании дополнительной клавиши.
local function UpdateModifierState()
    local frame = ActionBar.GetFrame()
    if not frame then
        return
    end

    local activeModifier = GetActiveModifier()

    ActionBar.SetBoostsExpanded(activeModifier == "SHIFT")

    for slotID, btn in pairs(frame.actionButtons) do
        local keepCross = not btn.modifierKey
            and ActionBar.IsBoostHostKey
            and ActionBar.IsBoostHostKey(btn.mainKey)
            and ActionBar.BoostFlipOwnsHosts
            and ActionBar.BoostFlipOwnsHosts()
        if IsActionButtonVisible(slotID, btn, activeModifier) or keepCross then
            ConsoleMenu:AnimatedShow(btn)
        else
            ConsoleMenu:AnimatedHide(btn)
        end
    end

    ActionBar.UpdateBoosts()
    UpdateActionButtonShadows()
    UpdateExploringFrameVisibility(activeModifier)
    if ActionBar.RefreshFaceButtonDesaturation then
        ActionBar.RefreshFaceButtonDesaturation()
    end
end

ActionBar.UpdateButtonPositions = UpdateButtonPositions
ActionBar.UpdateModifierState = UpdateModifierState
ActionBar.UpdateActionButtonShadows = UpdateActionButtonShadows
